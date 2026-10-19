// track: public (no JWT) lookup of an incident by its share token, for the guardian web tracker.
// A thin wrapper over the `track_incident` RPC, which already enforces the
// public-safe field set, the 24 h expiry and constant-shape lookups.
//
// Request  GET /track?token=<share_token>   or   POST { token }
// Response 200 <track_incident JSON>  |  404 { error, code: 'NOT_FOUND' }

import { corsHeaders, preflight } from "../_shared/cors.ts";
import { HttpError, json, requireMethod, toErrorResponse } from "../_shared/http.ts";
import type { EnvGetter } from "../_shared/types.ts";
import { isShareToken, readJsonObject } from "../_shared/validate.ts";

export interface TrackDeps {
  env: EnvGetter;
  /** Calls `track_incident(p_token)`; returns its JSON or null. */
  track(token: string): Promise<unknown | null>;
}

export async function handle(req: Request, deps: TrackDeps): Promise<Response> {
  const cors = corsHeaders(deps.env);
  const pre = preflight(req, deps.env);
  if (pre) return pre;

  try {
    requireMethod(req, "GET", "POST");
    const token = req.method === "GET"
      ? new URL(req.url).searchParams.get("token")
      : (await readJsonObject(req, 1024)).token;

    // Malformed and unknown tokens get the identical 404.
    const data = isShareToken(token) ? await deps.track(token) : null;
    if (data === null || data === undefined) throw new HttpError(404, "Not found");
    return json(data, 200, cors);
  } catch (e) {
    return toErrorResponse(e, cors, "track");
  }
}
