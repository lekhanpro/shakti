import { describe, expect, it } from 'vitest';
import { formatDistance, formatElapsed, formatRelative, isStale } from '../format';

describe('formatElapsed', () => {
  it('formats seconds, minutes and hours', () => {
    expect(formatElapsed(0)).toBe('0 s');
    expect(formatElapsed(45_900)).toBe('45 s');
    expect(formatElapsed(60_000)).toBe('1 min');
    expect(formatElapsed(252_000)).toBe('4 min 12 s');
    expect(formatElapsed(3_600_000)).toBe('1 h');
    expect(formatElapsed(3_780_000)).toBe('1 h 3 min');
  });
  it('clamps negative and non-finite input', () => {
    expect(formatElapsed(-5000)).toBe('0 s');
    expect(formatElapsed(Number.NaN)).toBe('0 s');
  });
});

describe('formatRelative', () => {
  const now = Date.parse('2026-09-29T10:00:00Z');
  it('reads "just now" under 5 s and for future times', () => {
    expect(formatRelative(now - 3000, now)).toBe('just now');
    expect(formatRelative(now + 30_000, now)).toBe('just now');
  });
  it('covers each unit', () => {
    expect(formatRelative(now - 12_000, now)).toBe('12 s ago');
    expect(formatRelative(new Date(now - 5 * 60_000), now)).toBe('5 min ago');
    expect(formatRelative('2026-09-29T07:00:00Z', now)).toBe('3 h ago');
    expect(formatRelative(now - 86_400_000, now)).toBe('1 day ago');
    expect(formatRelative(now - 3 * 86_400_000, new Date(now))).toBe('3 days ago');
  });
  it('handles unparseable input', () => {
    expect(formatRelative('not a date', now)).toBe('unknown');
  });
});

describe('isStale', () => {
  const now = 1_000_000;
  it('uses a 60 s threshold by default', () => {
    expect(isStale(now - 59_000, now)).toBe(false);
    expect(isStale(now - 60_000, now)).toBe(false);
    expect(isStale(now - 61_000, now)).toBe(true);
  });
  it('accepts a custom threshold', () => {
    expect(isStale(now - 20_000, now, 10_000)).toBe(true);
  });
  it('treats missing or bad input as stale', () => {
    expect(isStale(null, now)).toBe(true);
    expect(isStale(undefined, now)).toBe(true);
    expect(isStale('garbage', now)).toBe(true);
  });
});

describe('formatDistance', () => {
  it('switches to km at 1000 m', () => {
    expect(formatDistance(850.4)).toBe('850 m');
    expect(formatDistance(2400)).toBe('2.4 km');
    expect(formatDistance(12_600)).toBe('13 km');
    expect(formatDistance(-1)).toBe('0 m');
  });
});
