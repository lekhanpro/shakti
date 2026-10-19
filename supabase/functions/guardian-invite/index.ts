import { adminClient, requireUser } from "../_shared/auth.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { handle, type InviteDb, type InviteRow } from "./handler.ts";

const admin = () => adminClient();
const COLS = "id, owner_id, code, guardian_user_id, status, expires_at, revoked_at";

function fail(op: string, err: { code?: string } | null): never {
  throw new Error(`${op} failed: ${err?.code ?? "unknown"}`);
}

const db: InviteDb = {
  async countPending(ownerId, now) {
    const r = await admin()
      .from("guardian_invites")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", ownerId)
      .eq("status", "PENDING")
      .gt("expires_at", now.toISOString());
    if (r.error) fail("count", r.error);
    return r.count ?? 0;
  },
  async insert(row) {
    const r = await admin().from("guardian_invites").insert(row).select(COLS).single();
    if (r.error) {
      if (r.error.code === "23505") return null;
      fail("insert", r.error);
    }
    return r.data as InviteRow;
  },
  async findByCode(code) {
    const r = await admin().from("guardian_invites").select(COLS).eq("code", code).maybeSingle();
    if (r.error) fail("findByCode", r.error);
    return (r.data as InviteRow | null) ?? null;
  },
  async findById(id) {
    const r = await admin().from("guardian_invites").select(COLS).eq("id", id).maybeSingle();
    if (r.error) fail("findById", r.error);
    return (r.data as InviteRow | null) ?? null;
  },
  async accept(id, guardianId, now) {
    // Conditional update: only a still-PENDING, unexpired invite flips to ACCEPTED.
    const r = await admin()
      .from("guardian_invites")
      .update({ status: "ACCEPTED", guardian_user_id: guardianId, accepted_at: now.toISOString() })
      .eq("id", id)
      .eq("status", "PENDING")
      .is("guardian_user_id", null)
      .gt("expires_at", now.toISOString())
      .select("id");
    if (r.error) {
      if (r.error.code === "23505") return false; // pair already linked
      fail("accept", r.error);
    }
    return (r.data ?? []).length === 1;
  },
  async revoke(id, now) {
    const r = await admin()
      .from("guardian_invites")
      .update({ status: "REVOKED", revoked_at: now.toISOString() })
      .eq("id", id);
    if (r.error) fail("revoke", r.error);
  },
  async hasActiveLink(ownerId, guardianId) {
    const r = await admin()
      .from("guardian_invites")
      .select("id", { count: "exact", head: true })
      .eq("owner_id", ownerId)
      .eq("guardian_user_id", guardianId)
      .eq("status", "ACCEPTED")
      .is("revoked_at", null);
    if (r.error) fail("hasActiveLink", r.error);
    return (r.count ?? 0) > 0;
  },
  async displayName(userId) {
    const r = await admin().from("profiles").select("display_name").eq("id", userId).maybeSingle();
    if (r.error) return null;
    return (r.data?.display_name as string | undefined) ?? null;
  },
};

Deno.serve((req) =>
  handle(req, {
    env: (k) => Deno.env.get(k),
    fetch: globalThis.fetch.bind(globalThis),
    auth: requireUser,
    rateLimit: (userId, bucket, limit, windowSec) => checkRateLimit(admin(), userId, bucket, limit, windowSec),
    db,
  })
);
