import { describe, expect, it } from 'vitest';
import { googleMapsUrl, haversineM, totalDistance } from '../geo';

const majestic = { latitude: 12.9767, longitude: 77.5713 };
const mgRoad = { latitude: 12.9756, longitude: 77.6066 };

describe('haversineM', () => {
  it('is zero for identical points', () => {
    expect(haversineM(majestic, majestic)).toBe(0);
  });
  it('matches a known Bengaluru distance within 1%', () => {
    // ~3.83 km between Majestic and MG Road metro
    const d = haversineM(majestic, mgRoad);
    expect(d).toBeGreaterThan(3790);
    expect(d).toBeLessThan(3870);
  });
  it('is symmetric', () => {
    expect(haversineM(majestic, mgRoad)).toBeCloseTo(haversineM(mgRoad, majestic), 6);
  });
  it('gives one degree of latitude as ~111.2 km', () => {
    const d = haversineM({ latitude: 0, longitude: 0 }, { latitude: 1, longitude: 0 });
    expect(d / 1000).toBeCloseTo(111.2, 0);
  });
  it('handles antipodes without NaN', () => {
    const d = haversineM({ latitude: 0, longitude: 0 }, { latitude: 0, longitude: 180 });
    expect(Number.isFinite(d)).toBe(true);
    expect(d / 1000).toBeCloseTo(20015, -1);
  });
});

describe('totalDistance', () => {
  it('is zero for fewer than two points', () => {
    expect(totalDistance([])).toBe(0);
    expect(totalDistance([majestic])).toBe(0);
  });
  it('sums every segment', () => {
    const there = haversineM(majestic, mgRoad);
    expect(totalDistance([majestic, mgRoad, majestic])).toBeCloseTo(there * 2, 6);
  });
});

describe('googleMapsUrl', () => {
  it('builds a search URL with 6 decimal places', () => {
    expect(googleMapsUrl(mgRoad)).toBe(
      'https://www.google.com/maps/search/?api=1&query=12.975600,77.606600',
    );
  });
});
