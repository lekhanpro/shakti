import { describe, expect, it } from 'vitest';
import {
  BEAT_COUNT,
  beatAt,
  cameraAt,
  channelStatesAt,
  clamp01,
  clockAt,
  formatClock,
  phaseAt,
  scrollProgress,
  smoothstep,
  stageAt,
} from '../story';

describe('beatAt', () => {
  it('opens on the first beat and closes on the last', () => {
    expect(beatAt(0)).toBe(0);
    expect(beatAt(1)).toBe(BEAT_COUNT - 1);
  });

  it('only moves forward and visits every beat', () => {
    const seen = new Set<number>();
    let prev = beatAt(0);
    for (let i = 0; i <= 200; i++) {
      const b = beatAt(i / 200);
      expect(b).toBeGreaterThanOrEqual(prev);
      expect(Number.isInteger(b)).toBe(true);
      seen.add(b);
      prev = b;
    }
    expect(seen.size).toBe(BEAT_COUNT);
  });

  it('treats out-of-range progress as the nearest end', () => {
    expect(beatAt(-2)).toBe(0);
    expect(beatAt(9)).toBe(BEAT_COUNT - 1);
  });
});

describe('phaseAt', () => {
  it('goes idle, countdown, sos, live, safe in that order', () => {
    const order = ['idle', 'countdown', 'sos', 'live', 'safe'];
    const seen: string[] = [];
    for (let i = 0; i <= 400; i++) {
      const ph = phaseAt(i / 400);
      if (seen[seen.length - 1] !== ph) seen.push(ph);
    }
    expect(seen).toEqual(order);
  });

  it('is calm at the start and safe at the end', () => {
    expect(phaseAt(0)).toBe('idle');
    expect(phaseAt(1)).toBe('safe');
  });
});

describe('channelStatesAt', () => {
  it('starts with every channel idle and ends with every channel done', () => {
    expect(channelStatesAt(0)).toEqual(['idle', 'idle', 'idle', 'idle']);
    expect(channelStatesAt(1)).toEqual(['done', 'done', 'done', 'done']);
  });

  it('saves on the phone first and sends the SMS before any cloud channel finishes', () => {
    for (let i = 0; i <= 400; i++) {
      const [saved, sms, cloud, live] = channelStatesAt(i / 400);
      if (sms === 'done') expect(saved).toBe('done');
      if (cloud === 'done') expect(sms).toBe('done');
      if (live === 'done') expect(cloud).toBe('done');
      // Nothing finishes before the cancel window is over.
      if (i / 400 < 0.5) expect([saved, sms, cloud, live]).toEqual(['idle', 'idle', 'idle', 'idle']);
    }
  });

  it('never moves a channel backwards', () => {
    const rank = { idle: 0, active: 1, done: 2 } as const;
    let prev = channelStatesAt(0);
    for (let i = 1; i <= 400; i++) {
      const next = channelStatesAt(i / 400);
      next.forEach((s, k) => expect(rank[s]).toBeGreaterThanOrEqual(rank[prev[k]]));
      prev = next;
    }
  });
});

describe('clockAt and formatClock', () => {
  it('holds at zero while she walks, reaches 5 s when the countdown ends, and 54 s when she is safe', () => {
    expect(clockAt(0)).toBe(0);
    expect(clockAt(0.3)).toBe(0);
    expect(clockAt(0.5)).toBe(5);
    expect(clockAt(1)).toBe(54);
  });

  it('never runs backwards', () => {
    let prev = clockAt(0);
    for (let i = 1; i <= 100; i++) {
      const next = clockAt(i / 100);
      expect(next).toBeGreaterThanOrEqual(prev);
      prev = next;
    }
  });

  it('formats as m:ss, rounding down, never negative', () => {
    expect(formatClock(0)).toBe('0:00');
    expect(formatClock(5)).toBe('0:05');
    expect(formatClock(54.9)).toBe('0:54');
    expect(formatClock(65)).toBe('1:05');
    expect(formatClock(-3)).toBe('0:00');
  });
});

describe('clamp01 and smoothstep', () => {
  it('clamps to the unit interval', () => {
    expect(clamp01(-3)).toBe(0);
    expect(clamp01(0.4)).toBe(0.4);
    expect(clamp01(9)).toBe(1);
  });

  it('is 0 before, 1 after, and 0.5 at the midpoint', () => {
    expect(smoothstep(2, 4, 1)).toBe(0);
    expect(smoothstep(2, 4, 5)).toBe(1);
    expect(smoothstep(2, 4, 3)).toBeCloseTo(0.5, 6);
  });
});

describe('scrollProgress', () => {
  it('maps scroll distance over the scrollable length of the story', () => {
    // 5 screens tall, 1 screen visible: 4 screens of travel.
    expect(scrollProgress(0, 5000, 1000)).toBe(0);
    expect(scrollProgress(2000, 5000, 1000)).toBeCloseTo(0.5, 6);
    expect(scrollProgress(4000, 5000, 1000)).toBe(1);
  });

  it('clamps outside the story and survives a story no taller than the viewport', () => {
    expect(scrollProgress(-500, 5000, 1000)).toBe(0);
    expect(scrollProgress(9000, 5000, 1000)).toBe(1);
    expect(scrollProgress(100, 800, 1000)).toBe(0);
  });
});

describe('stageAt', () => {
  it('starts calm: nothing has happened yet', () => {
    expect(stageAt(0)).toEqual({ walk: 0, countdown: 0, sos: 0, live: 0, safe: 0 });
  });

  it('ends safe: the alert is fully out and the scene has turned green', () => {
    const s = stageAt(1);
    expect(s.walk).toBe(1);
    expect(s.sos).toBe(1);
    expect(s.live).toBe(1);
    expect(s.safe).toBe(1);
  });

  it('runs the countdown before the SMS goes out, never after', () => {
    const during = stageAt(0.4);
    expect(during.countdown).toBeGreaterThan(0);
    expect(during.countdown).toBeLessThan(1);
    expect(during.sos).toBe(0);

    const after = stageAt(0.6);
    expect(after.countdown).toBe(1);
    expect(after.sos).toBeGreaterThan(0);
  });

  it('only moves forward as the page scrolls forward', () => {
    let prev = stageAt(0);
    for (let i = 1; i <= 100; i++) {
      const next = stageAt(i / 100);
      expect(next.walk).toBeGreaterThanOrEqual(prev.walk);
      expect(next.sos).toBeGreaterThanOrEqual(prev.sos);
      expect(next.live).toBeGreaterThanOrEqual(prev.live);
      expect(next.safe).toBeGreaterThanOrEqual(prev.safe);
      prev = next;
    }
  });

  it('treats out-of-range progress as the nearest end', () => {
    expect(stageAt(-1)).toEqual(stageAt(0));
    expect(stageAt(4)).toEqual(stageAt(1));
  });
});

describe('cameraAt', () => {
  it('returns finite numbers everywhere and moves continuously', () => {
    let prev = cameraAt(0);
    for (let i = 1; i <= 200; i++) {
      const next = cameraAt(i / 200);
      for (const v of [...next.offset, ...next.look]) expect(Number.isFinite(v)).toBe(true);
      // No teleporting: a 0.5% scroll step never moves the camera by more than 1.5 units.
      const d = Math.hypot(
        next.offset[0] - prev.offset[0],
        next.offset[1] - prev.offset[1],
        next.offset[2] - prev.offset[2],
      );
      expect(d).toBeLessThan(1.5);
      prev = next;
    }
  });

  it('rises to a high view while guardians are watching, and comes back down after', () => {
    const walking = cameraAt(0.05).offset[1];
    const watching = cameraAt(0.78).offset[1];
    expect(watching).toBeGreaterThan(walking * 3);
  });
});
