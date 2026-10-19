import type { RateLimitResult } from "./types.ts";

/** Minimal slice of a supabase-js client needed by the limiter. */
export interface RpcClient {
  rpc(
    fn: string,
    args: Record<string, unknown>,
  ): PromiseLike<{ data: unknown; error: { message: string } | null }>;
}

/**
 * Fixed-window limiter backed by the `bump_rate_limit` SQL function, which does
 * an atomic `insert ... on conflict do update ... returning count`.
 *
 * Fails OPEN (allowed, count null) if the database errors: in a safety app a
 * limiter outage must not block an SOS or a help request.
 */
export async function checkRateLimit(
  admin: RpcClient,
  userId: string,
  bucket: string,
  limit: number,
  windowSec: number,
): Promise<RateLimitResult> {
  try {
    const { data, error } = await admin.rpc("bump_rate_limit", {
      p_user_id: userId,
      p_bucket: bucket,
      p_window_sec: windowSec,
    });
    if (error) throw new Error(error.message);
    const count = typeof data === "number" ? data : Number(data);
    if (!Number.isFinite(count)) throw new Error("unexpected rate limit result");
    return { allowed: count <= limit, count, retryAfterSec: windowSec };
  } catch (e) {
    console.error(`[rate_limit] failing open for bucket=${bucket}: ${e instanceof Error ? e.message.slice(0, 200) : "error"}`);
    return { allowed: true, count: null, retryAfterSec: 0 };
  }
}
