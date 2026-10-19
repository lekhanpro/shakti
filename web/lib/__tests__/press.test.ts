import { describe, expect, it } from 'vitest';
import { PRESS_COUNT, PRESS_WINDOW_MS, pushPress } from '../press';

describe('pushPress (mirrors the app PowerPressDetector)', () => {
  it('matches the app: 3 presses inside 1200 ms', () => {
    expect(PRESS_COUNT).toBe(3);
    expect(PRESS_WINDOW_MS).toBe(1200);
  });

  it('does not trigger on the first or second press', () => {
    let r = pushPress([], 0);
    expect(r.triggered).toBe(false);
    r = pushPress(r.history, 300);
    expect(r.triggered).toBe(false);
    expect(r.history).toEqual([0, 300]);
  });

  it('triggers on the third press inside the window, then resets', () => {
    let r = pushPress([], 0);
    r = pushPress(r.history, 400);
    r = pushPress(r.history, 900);
    expect(r.triggered).toBe(true);
    expect(r.history).toEqual([]);
  });

  it('does not trigger when the presses are spread too far apart', () => {
    let r = pushPress([], 0);
    r = pushPress(r.history, 700);
    r = pushPress(r.history, 1400);
    expect(r.triggered).toBe(false);
    // The press at 0 has aged out; the other two remain.
    expect(r.history).toEqual([700, 1400]);
  });

  it('still triggers when a slow press is followed by two quick ones', () => {
    let r = pushPress([], 0);
    r = pushPress(r.history, 2000);
    r = pushPress(r.history, 2300);
    r = pushPress(r.history, 2600);
    expect(r.triggered).toBe(true);
  });

  it('counts the fourth press after a trigger as the start of a new run', () => {
    let r = pushPress([], 0);
    r = pushPress(r.history, 100);
    r = pushPress(r.history, 200);
    expect(r.triggered).toBe(true);
    r = pushPress(r.history, 300);
    expect(r.triggered).toBe(false);
    expect(r.history).toEqual([300]);
  });

  it('does not mutate the history it is given', () => {
    const before = [0, 100];
    pushPress(before, 200);
    expect(before).toEqual([0, 100]);
  });
});
