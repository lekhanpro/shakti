// Small hand-written validators. Each throws HttpError(400) with a message that
// names the field but never echoes the offending value back.

import { HttpError } from "./http.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const SHARE_TOKEN_RE = /^[A-Za-z0-9_-]{22,64}$/;
const TELEGRAM_CHAT_RE = /^(-?[0-9]{1,20}|@[A-Za-z][A-Za-z0-9_]{4,31})$/;
// C0/C1 control characters except tab, newline and carriage return.
// deno-lint-ignore no-control-regex
const CONTROL_RE = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/g;

export function bad(message: string): HttpError {
  return new HttpError(400, message, "BAD_REQUEST");
}

export function isUuid(v: unknown): v is string {
  return typeof v === "string" && UUID_RE.test(v);
}

export function isShareToken(v: unknown): v is string {
  return typeof v === "string" && SHARE_TOKEN_RE.test(v);
}

export function isTelegramChatId(v: unknown): v is string {
  return typeof v === "string" && TELEGRAM_CHAT_RE.test(v);
}

export function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** Removes control characters (keeps \t \n \r) and trims. */
export function sanitizeText(s: string): string {
  return s.replace(CONTROL_RE, "").trim();
}

/**
 * Lenient string: returns a sanitized string truncated to `max` chars, or
 * `fallback` when the value is missing, not a string, or empty.
 */
export function clampString(v: unknown, max: number, fallback = ""): string {
  if (typeof v !== "string") return fallback;
  const s = sanitizeText(v);
  if (!s) return fallback;
  return [...s].slice(0, max).join("");
}

/** Strict string: must be present, and at most `max` chars after sanitizing. */
export function requireString(v: unknown, field: string, opts: { min?: number; max: number }): string {
  if (typeof v !== "string") throw bad(`${field} must be a string`);
  const s = sanitizeText(v);
  const len = [...s].length;
  if (len < (opts.min ?? 1)) throw bad(`${field} is empty`);
  if (len > opts.max) throw bad(`${field} exceeds ${opts.max} characters`);
  return s;
}

/** Finite number in [min, max]. `null`/`undefined` returns undefined when optional. */
export function numberInRange(
  v: unknown,
  field: string,
  min: number,
  max: number,
  opts: { optional?: boolean; integer?: boolean } = {},
): number | undefined {
  if (v === null || v === undefined) {
    if (opts.optional) return undefined;
    throw bad(`${field} is required`);
  }
  if (typeof v !== "number" || !Number.isFinite(v)) throw bad(`${field} must be a number`);
  if (v < min || v > max) throw bad(`${field} out of range`);
  if (opts.integer && !Number.isInteger(v)) throw bad(`${field} must be an integer`);
  return v;
}

export function optionalBoolean(v: unknown, field: string, fallback = false): boolean {
  if (v === null || v === undefined) return fallback;
  if (typeof v !== "boolean") throw bad(`${field} must be a boolean`);
  return v;
}

/** ISO-8601 timestamp within a sane window (year 2020 to one day in the future). */
export function isoTimestamp(v: unknown, field: string, now: Date, opts: { optional?: boolean } = {}): string | undefined {
  if (v === null || v === undefined) {
    if (opts.optional) return undefined;
    throw bad(`${field} is required`);
  }
  if (typeof v !== "string" || v.length > 40) throw bad(`${field} must be an ISO timestamp`);
  const t = Date.parse(v);
  if (Number.isNaN(t)) throw bad(`${field} must be an ISO timestamp`);
  if (t < Date.UTC(2020, 0, 1) || t > now.getTime() + 86_400_000) throw bad(`${field} out of range`);
  return new Date(t).toISOString();
}

export function oneOf<T extends string>(v: unknown, field: string, allowed: readonly T[]): T {
  if (typeof v !== "string" || !(allowed as readonly string[]).includes(v)) {
    throw bad(`${field} must be one of ${allowed.join(", ")}`);
  }
  return v as T;
}

/**
 * Reads a JSON object body with a byte cap. 415 for non-JSON content types,
 * 413 when too large, 400 for malformed JSON or a non-object top level.
 */
export async function readJsonObject(req: Request, maxBytes = 64 * 1024): Promise<Record<string, unknown>> {
  const type = req.headers.get("content-type") ?? "";
  if (type && !type.toLowerCase().includes("application/json")) {
    throw new HttpError(415, "Content-Type must be application/json");
  }
  const declared = Number(req.headers.get("content-length") ?? "0");
  if (declared > maxBytes) throw new HttpError(413, "Request body too large");

  const buf = new Uint8Array(await req.arrayBuffer());
  if (buf.byteLength > maxBytes) throw new HttpError(413, "Request body too large");

  let parsed: unknown;
  try {
    parsed = JSON.parse(new TextDecoder().decode(buf));
  } catch {
    throw bad("Malformed JSON");
  }
  if (!isPlainObject(parsed)) throw bad("Body must be a JSON object");
  return parsed;
}
