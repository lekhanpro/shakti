/**
 * Types and defensive parsing for the `track_incident(p_token)` RPC response.
 * The RPC is public (anon key), so treat its JSON as untrusted input.
 */

export type IncidentStatus = 'ACTIVE' | 'RESOLVED' | 'FALSE_ALARM' | 'COUNTDOWN';

export interface TrackIncident {
  status: IncidentStatus;
  created_at: string;
  updated_at: string;
  trigger_label: string | null;
  address: string | null;
  battery: number | null;
  first_name: string;
}

export interface Breadcrumb {
  latitude: number;
  longitude: number;
  speed_kmh: number | null;
  accuracy_meters: number | null;
  battery_percentage: number | null;
  recorded_at: string;
}

export interface TrackData {
  incident: TrackIncident;
  /** Valid points only, oldest first. */
  breadcrumbs: Breadcrumb[];
}

export type ParseResult =
  | { ok: true; data: TrackData }
  | { ok: false; reason: 'not_found' | 'invalid' };

const STATUSES: readonly IncidentStatus[] = ['ACTIVE', 'RESOLVED', 'FALSE_ALARM', 'COUNTDOWN'];
const MAX_TEXT = 300;
const MAX_POINTS = 5000;

const isObj = (v: unknown): v is Record<string, unknown> =>
  typeof v === 'object' && v !== null && !Array.isArray(v);

function num(v: unknown): number | null {
  if (typeof v === 'number' && Number.isFinite(v)) return v;
  if (typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v))) return Number(v);
  return null;
}

function text(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  const t = v.trim();
  return t === '' ? null : t.slice(0, MAX_TEXT);
}

function isoDate(v: unknown): string | null {
  if (typeof v !== 'string') return null;
  return Number.isNaN(Date.parse(v)) ? null : v;
}

function percent(v: unknown): number | null {
  const n = num(v);
  if (n === null || n < 0 || n > 100) return null;
  return Math.round(n);
}

function nonNegative(v: unknown): number | null {
  const n = num(v);
  return n === null || n < 0 ? null : n;
}

function parseBreadcrumb(v: unknown): Breadcrumb | null {
  if (!isObj(v)) return null;
  const latitude = num(v.latitude ?? v.lat);
  const longitude = num(v.longitude ?? v.lng);
  const recorded_at = isoDate(v.recorded_at);
  if (latitude === null || longitude === null || recorded_at === null) return null;
  if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) return null;
  // 0,0 ("null island") is almost always a missing fix, not a real location.
  if (latitude === 0 && longitude === 0) return null;
  return {
    latitude,
    longitude,
    speed_kmh: nonNegative(v.speed_kmh),
    accuracy_meters: nonNegative(v.accuracy_meters),
    battery_percentage: percent(v.battery_percentage ?? v.battery),
    recorded_at,
  };
}

/** Validates the RPC payload. `null`/empty means the token is unknown or expired. */
export function parseTrackResponse(raw: unknown): ParseResult {
  if (raw === null || raw === undefined) return { ok: false, reason: 'not_found' };
  let value: unknown = raw;
  if (typeof raw === 'string') {
    try {
      value = JSON.parse(raw);
    } catch {
      return { ok: false, reason: 'invalid' };
    }
    if (value === null) return { ok: false, reason: 'not_found' };
  }
  if (!isObj(value)) return { ok: false, reason: 'invalid' };
  // The database returns one flat object (status, last_address, breadcrumbs with
  // lat/lng/battery). A nested { incident, breadcrumbs } shape is also accepted.
  const flat = value.incident === undefined && typeof value.status === 'string';
  if (!flat && (value.incident === null || value.incident === undefined)) return { ok: false, reason: 'not_found' };
  if (!flat && !isObj(value.incident)) return { ok: false, reason: 'invalid' };

  const i: Record<string, unknown> = flat ? { ...value, address: value.last_address } : (value.incident as Record<string, unknown>);
  const status = typeof i.status === 'string' ? (i.status.toUpperCase() as IncidentStatus) : null;
  const created_at = isoDate(i.created_at);
  if (!status || !STATUSES.includes(status) || !created_at) return { ok: false, reason: 'invalid' };

  const incident: TrackIncident = {
    status,
    created_at,
    updated_at: isoDate(i.updated_at) ?? created_at,
    trigger_label: text(i.trigger_label),
    address: text(i.address),
    battery: percent(i.battery),
    first_name: text(i.first_name)?.slice(0, 40) ?? 'Your contact',
  };

  const rawCrumbs = Array.isArray(value.breadcrumbs) ? value.breadcrumbs.slice(-MAX_POINTS) : [];
  const breadcrumbs = rawCrumbs
    .map(parseBreadcrumb)
    .filter((b): b is Breadcrumb => b !== null)
    .sort((a, b) => Date.parse(a.recorded_at) - Date.parse(b.recorded_at));

  // Early in an incident there are no breadcrumbs yet: show where the SOS began.
  if (flat && breadcrumbs.length === 0) {
    const seed = parseBreadcrumb({
      latitude: i.latitude,
      longitude: i.longitude,
      battery_percentage: i.battery,
      recorded_at: incident.updated_at,
    });
    if (seed) breadcrumbs.push(seed);
  }

  return { ok: true, data: { incident, breadcrumbs } };
}

/** Latest known battery level: newest breadcrumb, then the incident row. */
export function latestBattery(data: TrackData): number | null {
  for (let k = data.breadcrumbs.length - 1; k >= 0; k--) {
    const b = data.breadcrumbs[k].battery_percentage;
    if (b !== null) return b;
  }
  return data.incident.battery;
}

/** Most recent timestamp we have for this incident. */
export function lastUpdateIso(data: TrackData): string {
  const last = data.breadcrumbs.at(-1)?.recorded_at;
  if (last && Date.parse(last) > Date.parse(data.incident.updated_at)) return last;
  return data.incident.updated_at;
}
