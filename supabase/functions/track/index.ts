import { createClient } from "npm:@supabase/supabase-js@2";
import { handle } from "./handler.ts";

// Anon client: the RPC is SECURITY DEFINER and granted to anon, so no service role is needed here.
const client = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
});

Deno.serve((req) =>
  handle(req, {
    env: (k) => Deno.env.get(k),
    async track(token) {
      const { data, error } = await client.rpc("track_incident", { p_token: token });
      if (error) throw new Error(`track_incident failed: ${error.code ?? "unknown"}`);
      return data ?? null;
    },
  })
);
