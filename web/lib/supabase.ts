import { createClient, type SupabaseClient } from '@supabase/supabase-js';

export interface SupabaseConfig {
  url: string;
  anonKey: string;
}

/** Reads public config. Returns null when either value is missing or the URL is malformed. */
export function readSupabaseConfig(): SupabaseConfig | null {
  // Literal property access so Next.js inlines the values at build time.
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  if (!url || !anonKey) return null;
  try {
    new URL(url);
  } catch {
    return null;
  }
  return { url, anonKey };
}

let client: SupabaseClient | null = null;

/** Lazily created browser client. Guardians are anonymous: no session is persisted. */
export function getSupabase(config: SupabaseConfig): SupabaseClient {
  if (!client) {
    client = createClient(config.url, config.anonKey, {
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });
  }
  return client;
}
