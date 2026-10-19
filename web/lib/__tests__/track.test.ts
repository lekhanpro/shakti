import { describe, expect, it } from 'vitest';
import { lastUpdateIso, latestBattery, parseTrackResponse } from '../track';

const incident = {
  status: 'ACTIVE',
  created_at: '2026-09-29T10:00:00Z',
  updated_at: '2026-09-29T10:02:00Z',
  trigger_label: 'Shake',
  address: 'MG Road, Bengaluru',
  battery: 54,
  first_name: 'Asha',
};
const crumb = (lat: number, lon: number, at: string, extra: Record<string, unknown> = {}) => ({
  latitude: lat,
  longitude: lon,
  speed_kmh: 4,
  accuracy_meters: 12,
  battery_percentage: 50,
  recorded_at: at,
  ...extra,
});

describe('parseTrackResponse', () => {
  it('treats null, undefined and a null incident as not found', () => {
    expect(parseTrackResponse(null)).toEqual({ ok: false, reason: 'not_found' });
    expect(parseTrackResponse(undefined)).toEqual({ ok: false, reason: 'not_found' });
    expect(parseTrackResponse({ incident: null, breadcrumbs: [] })).toEqual({ ok: false, reason: 'not_found' });
    expect(parseTrackResponse('null')).toEqual({ ok: false, reason: 'not_found' });
  });

  it('rejects non-object and malformed payloads', () => {
    expect(parseTrackResponse(42)).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTrackResponse([])).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTrackResponse('{oops')).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTrackResponse({ incident: 'x' })).toEqual({ ok: false, reason: 'invalid' });
    expect(parseTrackResponse({ incident: { ...incident, status: 'PANIC' } }).ok).toBe(false);
    expect(parseTrackResponse({ incident: { ...incident, created_at: 'yesterday' } }).ok).toBe(false);
  });

  it('parses a valid payload and sorts breadcrumbs oldest first', () => {
    const r = parseTrackResponse({
      incident,
      breadcrumbs: [
        crumb(12.98, 77.6, '2026-09-29T10:01:00Z'),
        crumb(12.97, 77.6, '2026-09-29T10:00:30Z'),
      ],
    });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.data.incident.first_name).toBe('Asha');
    expect(r.data.breadcrumbs.map((b) => b.latitude)).toEqual([12.97, 12.98]);
  });

  it('accepts a JSON string and lower-case status', () => {
    const r = parseTrackResponse(JSON.stringify({ incident: { ...incident, status: 'resolved' }, breadcrumbs: [] }));
    expect(r.ok && r.data.incident.status).toBe('RESOLVED');
  });

  it('drops invalid breadcrumbs instead of failing', () => {
    const r = parseTrackResponse({
      incident,
      breadcrumbs: [
        crumb(95, 77, '2026-09-29T10:00:00Z'),
        crumb(0, 0, '2026-09-29T10:00:00Z'),
        crumb(12.9, 77.6, 'nope'),
        { latitude: 'abc', longitude: 1, recorded_at: '2026-09-29T10:00:00Z' },
        null,
        crumb(12.9, 77.6, '2026-09-29T10:00:10Z', { battery_percentage: 140, speed_kmh: -3 }),
      ],
    });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.data.breadcrumbs).toHaveLength(1);
    expect(r.data.breadcrumbs[0].battery_percentage).toBeNull();
    expect(r.data.breadcrumbs[0].speed_kmh).toBeNull();
  });

  it('coerces numeric strings and fills safe defaults', () => {
    const r = parseTrackResponse({
      incident: { status: 'ACTIVE', created_at: '2026-09-29T10:00:00Z', battery: '77', first_name: '  ' },
      breadcrumbs: [crumb('12.9' as unknown as number, '77.5' as unknown as number, '2026-09-29T10:00:00Z')],
    });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.data.incident.first_name).toBe('Your contact');
    expect(r.data.incident.updated_at).toBe('2026-09-29T10:00:00Z');
    expect(r.data.incident.battery).toBe(77);
    expect(r.data.incident.address).toBeNull();
    expect(r.data.breadcrumbs[0].latitude).toBe(12.9);
  });

  it('treats a missing breadcrumbs array as empty', () => {
    const r = parseTrackResponse({ incident });
    expect(r.ok && r.data.breadcrumbs).toEqual([]);
  });

  it('truncates overly long text', () => {
    const r = parseTrackResponse({ incident: { ...incident, address: 'a'.repeat(1000), first_name: 'b'.repeat(100) } });
    expect(r.ok && r.data.incident.address?.length).toBe(300);
    expect(r.ok && r.data.incident.first_name.length).toBe(40);
  });
});

// The exact shape built by public.track_incident() in supabase/migrations.
const rpcPayload = {
  status: 'ACTIVE',
  trigger_label: 'Power button pressed 3 times',
  created_at: '2026-09-29T10:00:00Z',
  updated_at: '2026-09-29T10:02:00Z',
  resolved_at: null,
  latitude: 12.97,
  longitude: 77.6,
  last_address: 'MG Road, Bengaluru',
  battery: 54,
  first_name: 'Asha',
  breadcrumbs: [
    { lat: 12.98, lng: 77.61, speed_kmh: 4, accuracy_meters: 9, battery: 52, recorded_at: '2026-09-29T10:01:00Z' },
    { lat: 12.97, lng: 77.6, speed_kmh: null, accuracy_meters: 12, battery: 53, recorded_at: '2026-09-29T10:00:30Z' },
  ],
};

describe('parseTrackResponse with the real track_incident shape', () => {
  it('reads the flat payload the database returns', () => {
    const r = parseTrackResponse(rpcPayload);
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.data.incident.address).toBe('MG Road, Bengaluru');
    expect(r.data.incident.first_name).toBe('Asha');
    expect(r.data.incident.status).toBe('ACTIVE');
    expect(r.data.breadcrumbs.map((b) => b.latitude)).toEqual([12.97, 12.98]);
    expect(r.data.breadcrumbs[1].longitude).toBe(77.61);
    expect(r.data.breadcrumbs[1].battery_percentage).toBe(52);
  });

  it('accepts the payload as a JSON string', () => {
    expect(parseTrackResponse(JSON.stringify(rpcPayload)).ok).toBe(true);
  });

  it('falls back to the incident position when there are no breadcrumbs yet', () => {
    const r = parseTrackResponse({ ...rpcPayload, breadcrumbs: [] });
    expect(r.ok).toBe(true);
    if (!r.ok) return;
    expect(r.data.breadcrumbs).toHaveLength(1);
    expect(r.data.breadcrumbs[0]).toMatchObject({ latitude: 12.97, longitude: 77.6, battery_percentage: 54 });
  });

  it('rejects a flat payload with an unknown status', () => {
    expect(parseTrackResponse({ ...rpcPayload, status: 'PANIC' })).toEqual({ ok: false, reason: 'invalid' });
  });
});

describe('latestBattery / lastUpdateIso', () => {
  it('prefers the newest breadcrumb', () => {
    const r = parseTrackResponse({
      incident,
      breadcrumbs: [crumb(12.9, 77.6, '2026-09-29T10:05:00Z', { battery_percentage: 31 })],
    });
    if (!r.ok) throw new Error('parse failed');
    expect(latestBattery(r.data)).toBe(31);
    expect(lastUpdateIso(r.data)).toBe('2026-09-29T10:05:00Z');
  });
  it('falls back to the incident row', () => {
    const r = parseTrackResponse({ incident, breadcrumbs: [] });
    if (!r.ok) throw new Error('parse failed');
    expect(latestBattery(r.data)).toBe(54);
    expect(lastUpdateIso(r.data)).toBe('2026-09-29T10:02:00Z');
  });
});
