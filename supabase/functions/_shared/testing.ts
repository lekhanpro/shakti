// Test doubles shared by handler_test.ts files. Not imported by production code.

import { HttpError } from "./http.ts";
import type { AuthFn, AuthUser, EnvGetter, RateLimitFn } from "./types.ts";

export const USER_A: AuthUser = { id: "11111111-1111-4111-8111-111111111111", email: "a@example.com" };
export const USER_B: AuthUser = { id: "22222222-2222-4222-8222-222222222222", email: "b@example.com" };

export function fakeEnv(vars: Record<string, string> = {}): EnvGetter {
  return (k) => vars[k];
}

/** Auth that accepts `Bearer good` as `user`, and rejects everything else with 401. */
export function fakeAuth(user: AuthUser = USER_A): AuthFn {
  return (req) => {
    if (req.headers.get("Authorization") === "Bearer good") return Promise.resolve(user);
    return Promise.reject(new HttpError(401, "Invalid or expired session"));
  };
}

/** In-memory fixed-window limiter; `calls` records every invocation. */
export function fakeRateLimit(opts: { failOpen?: boolean } = {}) {
  const counts = new Map<string, number>();
  const calls: Array<{ userId: string; bucket: string; limit: number; windowSec: number }> = [];
  const fn: RateLimitFn = (userId, bucket, limit, windowSec) => {
    calls.push({ userId, bucket, limit, windowSec });
    if (opts.failOpen) return Promise.resolve({ allowed: true, count: null, retryAfterSec: 0 });
    const key = `${userId}:${bucket}`;
    const n = (counts.get(key) ?? 0) + 1;
    counts.set(key, n);
    return Promise.resolve({ allowed: n <= limit, count: n, retryAfterSec: windowSec });
  };
  return { fn, calls, counts };
}

export interface RecordedRequest {
  url: string;
  init: RequestInit;
  body: unknown;
}

/** Fake fetch that records requests and answers through `responder`. */
export function fakeFetch(responder: (url: string, init: RequestInit) => Response | Promise<Response>) {
  const requests: RecordedRequest[] = [];
  const fn = (async (input: string | URL | Request, init: RequestInit = {}) => {
    const url = typeof input === "string" ? input : input instanceof URL ? input.href : input.url;
    let body: unknown = init.body;
    if (typeof init.body === "string") {
      try {
        body = JSON.parse(init.body);
      } catch {
        body = init.body;
      }
    }
    requests.push({ url, init, body });
    return await responder(url, init);
  }) as typeof fetch;
  return { fn, requests };
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

export function post(url: string, body: unknown, opts: { auth?: string | null; raw?: boolean } = {}): Request {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  const auth = opts.auth === undefined ? "Bearer good" : opts.auth;
  if (auth) headers.Authorization = auth;
  return new Request(url, {
    method: "POST",
    headers,
    body: opts.raw ? String(body) : JSON.stringify(body),
  });
}
