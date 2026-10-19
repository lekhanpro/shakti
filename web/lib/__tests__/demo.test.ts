import { describe, expect, it } from 'vitest';
import { DEMO_HEADSTART_S, DEMO_INTERVAL_S, demoTrack } from '../demo';
import { haversineM, totalDistance } from '../geo';
import { parseTrackResponse } from '../track';

describe('demoTrack', () => {
  it('is deterministic for the same seed and time', () => {
    expect(demoTrack(7, 30_000, 0)).toEqual(demoTrack(7, 30_000, 0));
  });

  it('differs between seeds', () => {
    const a = demoTrack(1, 60_000).breadcrumbs.at(-1)!;
    const b = demoTrack(2, 60_000).breadcrumbs.at(-1)!;
    expect(a.latitude === b.latitude && a.longitude === b.longitude).toBe(false);
  });

  it('adds one point per interval and keeps earlier points stable', () => {
    const early = demoTrack(3, 0).breadcrumbs;
    const later = demoTrack(3, DEMO_INTERVAL_S * 1000 * 2).breadcrumbs;
    expect(early).toHaveLength(DEMO_HEADSTART_S / DEMO_INTERVAL_S + 1);
    expect(later).toHaveLength(early.length + 2);
    expect(later.slice(0, early.length)).toEqual(early);
  });

  it('stays near Bengaluru at walking pace', () => {
    const { breadcrumbs } = demoTrack(11, 10 * 60_000);
    const start = { latitude: 12.9719, longitude: 77.6412 };
    for (const b of breadcrumbs) expect(haversineM(start, b)).toBeLessThan(3000);
    const avgStep = totalDistance(breadcrumbs) / (breadcrumbs.length - 1);
    expect(avgStep).toBeGreaterThan(5);
    expect(avgStep).toBeLessThan(25);
  });

  it('produces timestamps ending at the page-open time plus t', () => {
    const origin = Date.parse('2026-09-29T10:00:00Z');
    const d = demoTrack(5, 20_000, origin);
    expect(Date.parse(d.breadcrumbs.at(-1)!.recorded_at)).toBe(origin + 20_000);
    expect(d.incident.created_at).toBe(new Date(origin - DEMO_HEADSTART_S * 1000).toISOString());
  });

  it('round-trips through the RPC parser', () => {
    const d = demoTrack(9, 5000, Date.now());
    const r = parseTrackResponse(JSON.parse(JSON.stringify(d)));
    expect(r.ok).toBe(true);
    if (r.ok) expect(r.data.breadcrumbs).toHaveLength(d.breadcrumbs.length);
  });
});
