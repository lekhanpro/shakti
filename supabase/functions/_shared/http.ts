// JSON response helpers. Error responses carry a short message and a stable
// machine code only: never stack traces, upstream bodies or SQL errors.

export class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
    readonly code: string = defaultCode(status),
    readonly headers: Record<string, string> = {},
  ) {
    super(message);
    this.name = "HttpError";
  }
}

function defaultCode(status: number): string {
  switch (status) {
    case 400: return "BAD_REQUEST";
    case 401: return "UNAUTHORIZED";
    case 403: return "FORBIDDEN";
    case 404: return "NOT_FOUND";
    case 405: return "METHOD_NOT_ALLOWED";
    case 409: return "CONFLICT";
    case 413: return "PAYLOAD_TOO_LARGE";
    case 415: return "UNSUPPORTED_MEDIA_TYPE";
    case 429: return "RATE_LIMITED";
    case 502: return "UPSTREAM_ERROR";
    case 503: return "UNAVAILABLE";
    default: return status >= 500 ? "INTERNAL" : "ERROR";
  }
}

const baseHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "X-Content-Type-Options": "nosniff",
};

export function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), { status, headers: { ...baseHeaders, ...headers } });
}

export function error(
  status: number,
  message: string,
  code: string = defaultCode(status),
  headers: Record<string, string> = {},
): Response {
  return json({ error: message, code }, status, headers);
}

/**
 * Converts anything thrown inside a handler into a safe response.
 * HttpErrors keep their status/message; everything else becomes a generic 500
 * and only the error name/message (no stack) is logged server-side.
 */
export function toErrorResponse(e: unknown, headers: Record<string, string>, tag: string): Response {
  if (e instanceof HttpError) {
    return error(e.status, e.message, e.code, { ...headers, ...e.headers });
  }
  const msg = e instanceof Error ? `${e.name}: ${e.message}` : String(e);
  console.error(`[${tag}] unhandled: ${msg.slice(0, 300)}`);
  return error(500, "Internal error", "INTERNAL", headers);
}

/** Throws 405 unless the request uses one of `methods`. */
export function requireMethod(req: Request, ...methods: string[]): void {
  if (!methods.includes(req.method)) {
    throw new HttpError(405, "Method not allowed", "METHOD_NOT_ALLOWED", { Allow: methods.join(", ") });
  }
}
