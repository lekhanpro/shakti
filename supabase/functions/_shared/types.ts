// Types shared by handlers. Pure: no runtime imports, safe for unit tests.

/** The authenticated caller, as returned by `auth.getUser()`. */
export interface AuthUser {
  id: string;
  email?: string | null;
}

/** Reads one environment variable. `Deno.env.get` in production, a map in tests. */
export type EnvGetter = (key: string) => string | undefined;

/** Resolves the caller or throws `HttpError(401)`. */
export type AuthFn = (req: Request) => Promise<AuthUser>;

export interface RateLimitResult {
  allowed: boolean;
  /** Hits in the current window, or null when the limiter failed open. */
  count: number | null;
  retryAfterSec: number;
}

/** `checkRateLimit` bound to a DB client. */
export type RateLimitFn = (
  userId: string,
  bucket: string,
  limit: number,
  windowSec: number,
) => Promise<RateLimitResult>;

/** Dependencies every handler receives. Each function extends this with its own `db`. */
export interface BaseDeps {
  env: EnvGetter;
  fetch: typeof fetch;
  auth: AuthFn;
  rateLimit: RateLimitFn;
  now?: () => Date;
}
