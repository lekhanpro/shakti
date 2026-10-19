/** Time formatting helpers used by the guardian tracker. Pure, no DOM. */

/** Formats a duration as "45 s", "4 min 12 s", "1 h 3 min". Negative values clamp to 0. */
export function formatElapsed(ms: number): string {
  if (!Number.isFinite(ms) || ms < 0) ms = 0;
  const totalS = Math.floor(ms / 1000);
  const h = Math.floor(totalS / 3600);
  const m = Math.floor((totalS % 3600) / 60);
  const s = totalS % 60;
  if (h > 0) return m > 0 ? `${h} h ${m} min` : `${h} h`;
  if (m > 0) return s > 0 ? `${m} min ${s} s` : `${m} min`;
  return `${s} s`;
}

/**
 * Human "time ago" for a past instant relative to `now`.
 * Under 5 s reads "just now". Future instants (clock skew) also read "just now".
 */
export function formatRelative(then: Date | string | number, now: Date | number = Date.now()): string {
  const t = toMs(then);
  const n = typeof now === 'number' ? now : now.getTime();
  if (Number.isNaN(t)) return 'unknown';
  const diffS = Math.floor((n - t) / 1000);
  if (diffS < 5) return 'just now';
  if (diffS < 60) return `${diffS} s ago`;
  const m = Math.floor(diffS / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h} h ago`;
  const d = Math.floor(h / 24);
  return d === 1 ? '1 day ago' : `${d} days ago`;
}

/** True when `then` is older than `thresholdMs` (default 60 s), or unparseable. */
export function isStale(
  then: Date | string | number | null | undefined,
  now: Date | number = Date.now(),
  thresholdMs = 60_000,
): boolean {
  if (then === null || then === undefined) return true;
  const t = toMs(then);
  if (Number.isNaN(t)) return true;
  const n = typeof now === 'number' ? now : now.getTime();
  return n - t > thresholdMs;
}

/** Formats metres as "850 m" or "2.4 km". */
export function formatDistance(m: number): string {
  if (!Number.isFinite(m) || m < 0) m = 0;
  if (m < 1000) return `${Math.round(m)} m`;
  return `${(m / 1000).toFixed(m < 10_000 ? 1 : 0)} km`;
}

function toMs(v: Date | string | number): number {
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  return Date.parse(v);
}
