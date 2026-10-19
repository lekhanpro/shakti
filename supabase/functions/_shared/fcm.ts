// Optional Firebase Cloud Messaging (HTTP v1) sender.
// Configure with FCM_SERVICE_ACCOUNT = the service-account JSON (single line).
// When unset, every call is a silent no-op returning 0.

import type { EnvGetter } from "./types.ts";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface PushMessage {
  title: string;
  body: string;
  data?: Record<string, string>;
}

const SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const DEFAULT_TOKEN_URI = "https://oauth2.googleapis.com/token";
const TIMEOUT_MS = 5_000;

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function b64urlJson(v: unknown): string {
  return b64url(new TextEncoder().encode(JSON.stringify(v)));
}

function pemToDer(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN [^-]+-----/, "")
    .replace(/-----END [^-]+-----/, "")
    .replace(/\\n/g, "")
    .replace(/\s+/g, "");
  const bin = atob(body);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

export function parseServiceAccount(raw: string | undefined): ServiceAccount | null {
  if (!raw?.trim()) return null;
  try {
    const sa = JSON.parse(raw) as Partial<ServiceAccount>;
    if (typeof sa.project_id !== "string" || typeof sa.client_email !== "string" ||
      typeof sa.private_key !== "string") return null;
    return sa as ServiceAccount;
  } catch {
    return null;
  }
}

/** Builds and RS256-signs the OAuth assertion JWT (RFC 7523) with WebCrypto. */
export async function signServiceAccountJwt(sa: ServiceAccount, nowSec: number): Promise<string> {
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri ?? DEFAULT_TOKEN_URI,
    iat: nowSec,
    exp: nowSec + 3600,
  };
  const unsigned = `${b64urlJson(header)}.${b64urlJson(claims)}`;
  const der = pemToDer(sa.private_key);
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der.buffer.slice(der.byteOffset, der.byteOffset + der.byteLength) as ArrayBuffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
  );
  return `${unsigned}.${b64url(sig)}`;
}

let cached: { token: string; exp: number; email: string } | null = null;

async function withTimeout(fetchImpl: typeof fetch, url: string, init: RequestInit): Promise<Response> {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    return await fetchImpl(url, { ...init, signal: ctrl.signal });
  } finally {
    clearTimeout(t);
  }
}

async function accessToken(sa: ServiceAccount, fetchImpl: typeof fetch, nowSec: number): Promise<string | null> {
  if (cached && cached.email === sa.client_email && cached.exp - 60 > nowSec) return cached.token;
  const assertion = await signServiceAccountJwt(sa, nowSec);
  const res = await withTimeout(fetchImpl, sa.token_uri ?? DEFAULT_TOKEN_URI, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) {
    await res.body?.cancel();
    console.warn(`[fcm] token exchange failed: HTTP ${res.status}`);
    return null;
  }
  const j = await res.json() as { access_token?: string; expires_in?: number };
  if (!j.access_token) return null;
  cached = { token: j.access_token, exp: nowSec + (j.expires_in ?? 3600), email: sa.client_email };
  return j.access_token;
}

/**
 * Sends `msg` to each device token. Returns how many sends succeeded.
 * Returns 0 without any network call when FCM_SERVICE_ACCOUNT is unset or invalid.
 * Never throws.
 */
export async function sendPush(
  env: EnvGetter,
  tokens: string[],
  msg: PushMessage,
  fetchImpl: typeof fetch = fetch,
  now: () => Date = () => new Date(),
): Promise<number> {
  const sa = parseServiceAccount(env("FCM_SERVICE_ACCOUNT"));
  if (!sa || tokens.length === 0) return 0;
  try {
    const bearer = await accessToken(sa, fetchImpl, Math.floor(now().getTime() / 1000));
    if (!bearer) return 0;
    const url = `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(sa.project_id)}/messages:send`;
    const results = await Promise.allSettled(
      [...new Set(tokens)].slice(0, 100).map(async (token) => {
        const res = await withTimeout(fetchImpl, url, {
          method: "POST",
          headers: { Authorization: `Bearer ${bearer}`, "Content-Type": "application/json" },
          body: JSON.stringify({
            message: {
              token,
              notification: { title: msg.title, body: msg.body },
              data: msg.data ?? {},
              android: { priority: "HIGH", notification: { channel_id: "shakti_sos" } },
            },
          }),
        });
        await res.body?.cancel();
        return res.ok;
      }),
    );
    return results.filter((r) => r.status === "fulfilled" && r.value).length;
  } catch (e) {
    console.warn(`[fcm] send failed: ${e instanceof Error ? e.name : "error"}`);
    return 0;
  }
}

/** Test hook: clears the cached OAuth token. */
export function _resetFcmCache(): void {
  cached = null;
}
