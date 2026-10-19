import { adminClient, requireUser } from "../_shared/auth.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { handle } from "./handler.ts";

Deno.serve((req) =>
  handle(req, {
    env: (k) => Deno.env.get(k),
    fetch: globalThis.fetch.bind(globalThis),
    auth: requireUser,
    rateLimit: (userId, bucket, limit, windowSec) =>
      checkRateLimit(adminClient(), userId, bucket, limit, windowSec),
  })
);
