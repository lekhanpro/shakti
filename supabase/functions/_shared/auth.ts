// Runtime auth wiring. Only index.ts files import this module (it pulls in
// supabase-js); handlers receive `requireUser` through their deps.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { HttpError } from "./http.ts";
import type { AuthUser } from "./types.ts";

function env(key: string): string {
  const v = Deno.env.get(key);
  if (!v) throw new Error(`${key} is not set`);
  return v;
}

const clientOpts = {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
};

/**
 * Verifies the caller's JWT with Supabase Auth (`auth.getUser()` round-trips
 * to the auth server, so revoked sessions are rejected too).
 * Throws HttpError(401) when the header is missing or the token is invalid.
 */
export async function requireUser(req: Request): Promise<AuthUser> {
  const header = req.headers.get("Authorization") ?? "";
  const match = /^Bearer\s+(\S+)$/i.exec(header);
  if (!match) throw new HttpError(401, "Missing bearer token");

  const client = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    ...clientOpts,
    global: { headers: { Authorization: `Bearer ${match[1]}` } },
  });
  const { data, error } = await client.auth.getUser(match[1]);
  if (error || !data?.user) throw new HttpError(401, "Invalid or expired session");
  return { id: data.user.id, email: data.user.email ?? null };
}

let admin: SupabaseClient | null = null;

/** Service-role client (bypasses RLS). Server-side only; never expose the key. */
export function adminClient(): SupabaseClient {
  admin ??= createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), clientOpts);
  return admin;
}
