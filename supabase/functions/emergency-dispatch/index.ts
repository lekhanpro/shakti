import { adminClient, requireUser } from "../_shared/auth.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { type DispatchDb, handle, type IncidentRow, type UpsertResult } from "./handler.ts";

const admin = () => adminClient();

const db: DispatchDb = {
  async upsertOwnedIncident(userId: string, row: IncidentRow): Promise<UpsertResult> {
    // 1. Insert if absent. The client may reach the cloud here before its sync queue does.
    const ins = await admin()
      .from("incident_reports")
      .upsert({ ...row, user_id: userId }, { onConflict: "id", ignoreDuplicates: true });
    if (ins.error) {
      // 23505 on share_token (a different incident already uses it).
      if (ins.error.code === "23505") return { kind: "conflict" };
      throw new Error(`insert failed: ${ins.error.code ?? "unknown"}`);
    }

    // 2. Verify ownership of whatever row now exists.
    const sel = await admin()
      .from("incident_reports")
      .select("user_id, share_token")
      .eq("id", row.id)
      .maybeSingle();
    if (sel.error || !sel.data) throw new Error(`select failed: ${sel.error?.code ?? "missing"}`);
    if (sel.data.user_id !== userId) return { kind: "forbidden" };

    // 3. Apply mutable fields only (triggers also pin id/user_id/share_token/created_at).
    const upd = await admin()
      .from("incident_reports")
      .update({
        status: row.status,
        latitude: row.latitude,
        longitude: row.longitude,
        street_address: row.street_address,
        battery_level: row.battery_level,
        carrier_sms_dispatched: row.carrier_sms_dispatched,
        resolved_at: row.resolved_at,
      })
      .eq("id", row.id)
      .eq("user_id", userId);
    if (upd.error) throw new Error(`update failed: ${upd.error.code ?? "unknown"}`);

    return { kind: "ok", share_token: sel.data.share_token as string };
  },

  async guardianPushTokens(ownerId: string): Promise<string[]> {
    const g = await admin()
      .from("guardian_invites")
      .select("guardian_user_id")
      .eq("owner_id", ownerId)
      .eq("status", "ACCEPTED")
      .is("revoked_at", null)
      .not("guardian_user_id", "is", null);
    if (g.error) throw new Error(`guardians failed: ${g.error.code ?? "unknown"}`);
    const ids = [...new Set((g.data ?? []).map((r) => r.guardian_user_id as string))];
    if (ids.length === 0) return [];
    const t = await admin().from("push_tokens").select("token").in("user_id", ids).limit(200);
    if (t.error) throw new Error(`tokens failed: ${t.error.code ?? "unknown"}`);
    return (t.data ?? []).map((r) => r.token as string);
  },

  async markTelegramSent(incidentId: string): Promise<void> {
    const r = await admin()
      .from("incident_reports")
      .update({ telegram_broadcast_sent: true })
      .eq("id", incidentId);
    if (r.error) throw new Error(`mark failed: ${r.error.code ?? "unknown"}`);
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
