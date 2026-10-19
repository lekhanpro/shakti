// guardian-invite: create, accept and revoke guardian invite codes.
//
// Request  POST { action: 'create' }
//          POST { action: 'accept', code: string }
//          POST { action: 'revoke', id: uuid }
// Response 200 create -> { id, code, expires_at }
//              accept -> { id, owner_id, owner_name, status: 'ACCEPTED' }
//              revoke -> { id, status: 'REVOKED' }
// Errors   { error, code } with 400/401/403/404/405/409/410/429

import { corsHeaders, preflight } from "../_shared/cors.ts";
import { HttpError, json, requireMethod, toErrorResponse } from "../_shared/http.ts";
import type { BaseDeps } from "../_shared/types.ts";
import { bad, isUuid, oneOf, readJsonObject } from "../_shared/validate.ts";

/** Crockford base32 without I, L, O, U. */
export const CROCKFORD = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
export const CODE_LENGTH = 8;
export const CODE_RE = /^[0-9A-HJKMNP-TV-Z]{8}$/;
export const INVITE_TTL_MS = 7 * 24 * 60 * 60 * 1000;
export const RATE_LIMIT = { bucket: "guardian-invite", limit: 20, windowSec: 3600 } as const;
/** Cap on open invites a user can hold, to stop code-space squatting. */
export const MAX_PENDING = 10;

export interface InviteRow {
  id: string;
  owner_id: string;
  code: string;
  guardian_user_id: string | null;
  status: "PENDING" | "ACCEPTED" | "REVOKED";
  expires_at: string;
  revoked_at: string | null;
}

export interface InviteDb {
  countPending(ownerId: string, now: Date): Promise<number>;
  /** Inserts; returns null when the code collides (unique violation). */
  insert(row: { owner_id: string; code: string; expires_at: string }): Promise<InviteRow | null>;
  findByCode(code: string): Promise<InviteRow | null>;
  findById(id: string): Promise<InviteRow | null>;
  /** Accepts only if still PENDING; returns false if someone raced us. */
  accept(id: string, guardianId: string, now: Date): Promise<boolean>;
  revoke(id: string, now: Date): Promise<void>;
  /** True if `guardianId` already guards `ownerId`. */
  hasActiveLink(ownerId: string, guardianId: string): Promise<boolean>;
  displayName(userId: string): Promise<string | null>;
}

export interface InviteDeps extends BaseDeps {
  db: InviteDb;
  /** Random bytes source (crypto.getRandomValues in production). */
  random?: (n: number) => Uint8Array;
}

function defaultRandom(n: number): Uint8Array {
  return crypto.getRandomValues(new Uint8Array(n));
}

/** 8 Crockford base32 chars = 40 bits, from 5 random bytes with no modulo bias. */
export function generateCode(random: (n: number) => Uint8Array = defaultRandom): string {
  const bytes = random(5);
  let bits = 0n;
  for (const b of bytes) bits = (bits << 8n) | BigInt(b);
  let out = "";
  for (let i = CODE_LENGTH - 1; i >= 0; i--) out += CROCKFORD[Number((bits >> BigInt(i * 5)) & 31n)];
  return out;
}

/** Normalises user-typed codes: uppercase, drop spaces/hyphens, map O->0 and I/L->1. */
export function normalizeCode(input: unknown): string | null {
  if (typeof input !== "string" || input.length > 32) return null;
  const c = input.toUpperCase().replace(/[\s-]/g, "").replace(/O/g, "0").replace(/[IL]/g, "1");
  return CODE_RE.test(c) ? c : null;
}

export async function handle(req: Request, deps: InviteDeps): Promise<Response> {
  const cors = corsHeaders(deps.env);
  const pre = preflight(req, deps.env);
  if (pre) return pre;

  try {
    requireMethod(req, "POST");
    const user = await deps.auth(req);
    const now = deps.now?.() ?? new Date();
    const body = await readJsonObject(req, 4 * 1024);
    const action = oneOf(body.action, "action", ["create", "accept", "revoke"] as const);

    const rl = await deps.rateLimit(user.id, RATE_LIMIT.bucket, RATE_LIMIT.limit, RATE_LIMIT.windowSec);
    if (!rl.allowed) {
      throw new HttpError(429, "Too many invite requests. Try again later.", "RATE_LIMITED", {
        "Retry-After": String(rl.retryAfterSec),
      });
    }

    switch (action) {
      case "create": {
        if (await deps.db.countPending(user.id, now) >= MAX_PENDING) {
          throw new HttpError(409, "Too many open invites. Revoke one first.", "TOO_MANY_INVITES");
        }
        const expires_at = new Date(now.getTime() + INVITE_TTL_MS).toISOString();
        for (let attempt = 0; attempt < 5; attempt++) {
          const row = await deps.db.insert({
            owner_id: user.id,
            code: generateCode(deps.random ?? defaultRandom),
            expires_at,
          });
          if (row) return json({ id: row.id, code: row.code, expires_at: row.expires_at }, 200, cors);
        }
        throw new Error("could not allocate a unique invite code");
      }

      case "accept": {
        const code = normalizeCode(body.code);
        if (!code) throw bad("code must be 8 characters");
        const inv = await deps.db.findByCode(code);
        // Unknown, revoked and already-used codes all look the same to the caller.
        if (!inv || inv.status !== "PENDING" || inv.revoked_at) {
          throw new HttpError(404, "Invite not found or no longer valid");
        }
        if (inv.owner_id === user.id) throw new HttpError(400, "You cannot accept your own invite", "SELF_ACCEPT");
        if (Date.parse(inv.expires_at) <= now.getTime()) {
          throw new HttpError(410, "This invite has expired", "EXPIRED");
        }
        if (await deps.db.hasActiveLink(inv.owner_id, user.id)) {
          throw new HttpError(409, "You are already a guardian for this person", "ALREADY_GUARDIAN");
        }
        if (!await deps.db.accept(inv.id, user.id, now)) {
          throw new HttpError(404, "Invite not found or no longer valid");
        }
        const name = await deps.db.displayName(inv.owner_id);
        return json({
          id: inv.id,
          owner_id: inv.owner_id,
          owner_name: name?.split(/\s+/)[0] ?? "Shakti user",
          status: "ACCEPTED",
        }, 200, cors);
      }

      case "revoke": {
        if (!isUuid(body.id)) throw bad("id must be a UUID");
        const inv = await deps.db.findById(body.id.toLowerCase());
        // Either side may end the link: the owner revokes, the guardian steps down.
        if (!inv || (inv.owner_id !== user.id && inv.guardian_user_id !== user.id)) {
          throw new HttpError(404, "Invite not found");
        }
        if (inv.status !== "REVOKED") await deps.db.revoke(inv.id, now);
        return json({ id: inv.id, status: "REVOKED" }, 200, cors);
      }
    }
  } catch (e) {
    return toErrorResponse(e, cors, "guardian-invite");
  }
}
