import type { EnvGetter } from "./types.ts";

/**
 * CORS headers. The allowed origin comes from `ALLOWED_ORIGIN` (default `*`).
 * The mobile app does not need CORS; this exists for the web tracker and tooling.
 */
export function corsHeaders(env: EnvGetter): Record<string, string> {
  const origin = env("ALLOWED_ORIGIN")?.trim() || "*";
  const headers: Record<string, string> = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
    "Access-Control-Max-Age": "86400",
  };
  if (origin !== "*") headers["Vary"] = "Origin";
  return headers;
}

/** Returns a 204 preflight response for OPTIONS requests, otherwise null. */
export function preflight(req: Request, env: EnvGetter): Response | null {
  if (req.method !== "OPTIONS") return null;
  return new Response(null, { status: 204, headers: corsHeaders(env) });
}
