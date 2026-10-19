/**
 * Pure maths for the scroll story. The 3D scene reads one number, scroll
 * progress from 0 to 1, and everything it shows derives from it here, so the
 * choreography is testable without a browser or a GPU.
 */

export type Vec3 = readonly [number, number, number];

export const clamp01 = (x: number): number => (Number.isFinite(x) ? Math.min(1, Math.max(0, x)) : 0);

/** 0 below `a`, 1 above `b`, an S-curve between. */
export function smoothstep(a: number, b: number, x: number): number {
  const t = clamp01((x - a) / (b - a));
  return t * t * (3 - 2 * t);
}

/** Progress through a tall story section: 0 when its top meets the viewport top, 1 when its bottom meets the viewport bottom. */
export function scrollProgress(scrollY: number, totalHeight: number, viewportHeight: number): number {
  const travel = totalHeight - viewportHeight;
  if (travel <= 0) return 0;
  return clamp01(scrollY / travel);
}

export interface Stage {
  /** The walker moves along the street. */
  walk: number;
  /** The five-second cancel window: the ring closes. */
  countdown: number;
  /** The alert goes out: the SOS ring and the first SMS. */
  sos: number;
  /** Guardians are watching: the tracking link is live. */
  live: number;
  /** The user marks herself safe: the whole scene settles to green. */
  safe: number;
}

/** What has happened by scroll progress `p`. Each channel only ever moves forward. */
export function stageAt(p: number): Stage {
  const x = clamp01(p);
  return {
    walk: smoothstep(0, 0.3, x),
    countdown: smoothstep(0.3, 0.5, x),
    sos: smoothstep(0.5, 0.64, x),
    live: smoothstep(0.62, 0.84, x),
    safe: smoothstep(0.88, 0.98, x),
  };
}

/** Progress at which each beat of the story begins after the first. */
const BEAT_STARTS = [0.3, 0.5, 0.64, 0.86] as const;

/** Walking, cancel window, alert goes out, guardians watching, marked safe. */
export const BEAT_COUNT = BEAT_STARTS.length + 1;

/** Which text beat is current at progress `p`. */
export function beatAt(p: number): number {
  const x = clamp01(p);
  let beat = 0;
  for (const start of BEAT_STARTS) if (x >= start) beat++;
  return beat;
}

export type Phase = 'idle' | 'countdown' | 'sos' | 'live' | 'safe';
const PHASES: readonly Phase[] = ['idle', 'countdown', 'sos', 'live', 'safe'];

/** The emergency phase shown on the HUD. Follows the beats one to one. */
export function phaseAt(p: number): Phase {
  return PHASES[beatAt(p)];
}

export type ChannelState = 'idle' | 'active' | 'done';

/**
 * The SOS fan-out checklist: saved on the phone, SMS handed to the carrier,
 * cloud alerts, live tracking. Same order as the real pipeline: the local
 * save comes first and nothing starts until the cancel window has closed.
 */
const CHANNEL_WINDOWS: readonly (readonly [start: number, end: number])[] = [
  [0.5, 0.54],
  [0.52, 0.6],
  [0.6, 0.7],
  [0.7, 0.86],
];

export function channelStatesAt(p: number): ChannelState[] {
  const x = clamp01(p);
  return CHANNEL_WINDOWS.map(([start, end]) => (x < start ? 'idle' : x < end ? 'active' : 'done'));
}

/**
 * Seconds on the incident clock at progress `p`: frozen at 0 while she walks,
 * 5 s when the cancel window closes, 54 s when she marks herself safe. These
 * match the timings the app and the landing copy promise.
 */
export function clockAt(p: number): number {
  const x = clamp01(p);
  if (x < 0.5) return 5 * clamp01((x - 0.3) / 0.2);
  return 5 + 49 * clamp01((x - 0.5) / 0.5);
}

/** Whole seconds as m:ss, rounded down, never negative. */
export function formatClock(seconds: number): string {
  const s = Math.max(0, Math.floor(Number.isFinite(seconds) ? seconds : 0));
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`;
}

interface CameraKey {
  at: number;
  offset: Vec3;
  look: Vec3;
}

/**
 * Camera keyframes, relative to the walker. Street level while she walks,
 * tight and low during the countdown, then a long rise to a rooftop view
 * when guardians start watching, settling lower once she is safe.
 */
const CAMERA_KEYS: readonly CameraKey[] = [
  { at: 0, offset: [1.2, 2.6, 9], look: [0, 1.3, -4] },
  { at: 0.3, offset: [1.0, 2.0, 6], look: [0, 1.3, -2] },
  { at: 0.5, offset: [0.8, 1.7, 4.4], look: [0, 1.2, -0.6] },
  { at: 0.62, offset: [3, 3.5, 6], look: [0, 1.5, 0] },
  { at: 0.8, offset: [0, 16, 9], look: [0, 0, -2] },
  { at: 1, offset: [0, 10, 11], look: [0, 0, -2] },
];

const mix = (a: Vec3, b: Vec3, t: number): [number, number, number] => [
  a[0] + (b[0] - a[0]) * t,
  a[1] + (b[1] - a[1]) * t,
  a[2] + (b[2] - a[2]) * t,
];

export function cameraAt(p: number): { offset: [number, number, number]; look: [number, number, number] } {
  const x = clamp01(p);
  for (let i = 1; i < CAMERA_KEYS.length; i++) {
    const a = CAMERA_KEYS[i - 1];
    const b = CAMERA_KEYS[i];
    if (x <= b.at) {
      const t = smoothstep(a.at, b.at, x);
      return { offset: mix(a.offset, b.offset, t), look: mix(a.look, b.look, t) };
    }
  }
  const last = CAMERA_KEYS[CAMERA_KEYS.length - 1];
  return { offset: mix(last.offset, last.offset, 0), look: mix(last.look, last.look, 0) };
}
