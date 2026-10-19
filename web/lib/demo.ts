import type { Breadcrumb, TrackData } from './track';

/** Seconds between simulated fixes, matching the app's breadcrumb interval. */
export const DEMO_INTERVAL_S = 10;
/** The simulated incident begins this long before the demo page opens. */
export const DEMO_HEADSTART_S = 4 * 60;

const START = { latitude: 12.9719, longitude: 77.6412 }; // Indiranagar, Bengaluru
const WALK_MPS = 1.35; // brisk walk
const M_PER_DEG_LAT = 111_320;

/** Small deterministic PRNG (mulberry32) so a seed always yields the same route. */
function mulberry32(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/**
 * Simulated incident for presentations. Deterministic in (seed, t).
 * @param seed any integer; picks the route.
 * @param t milliseconds since the demo page opened (>= 0).
 * @param origin wall-clock ms at which the demo page opened; timestamps are relative to it.
 */
export function demoTrack(seed: number, t: number, origin = 0): TrackData {
  const elapsedS = Math.max(0, t) / 1000 + DEMO_HEADSTART_S;
  const count = Math.floor(elapsedS / DEMO_INTERVAL_S) + 1;
  const rand = mulberry32(seed);
  const startMs = origin - DEMO_HEADSTART_S * 1000;

  const points: Breadcrumb[] = [];
  let { latitude, longitude } = START;
  let heading = rand() * Math.PI * 2;
  for (let k = 0; k < count; k++) {
    if (k > 0) {
      // Gentle wandering, with an occasional street corner.
      heading += (rand() - 0.5) * 0.5 + (rand() < 0.08 ? (rand() < 0.5 ? -1 : 1) * Math.PI / 2 : 0);
      const step = WALK_MPS * DEMO_INTERVAL_S * (0.7 + rand() * 0.6);
      latitude += (Math.cos(heading) * step) / M_PER_DEG_LAT;
      longitude += (Math.sin(heading) * step) / (M_PER_DEG_LAT * Math.cos((latitude * Math.PI) / 180));
    }
    points.push({
      latitude,
      longitude,
      speed_kmh: Math.round((3.5 + rand() * 2.5) * 10) / 10,
      accuracy_meters: Math.round(6 + rand() * 18),
      battery_percentage: Math.max(5, 68 - Math.floor((k * DEMO_INTERVAL_S) / 180)),
      recorded_at: new Date(startMs + k * DEMO_INTERVAL_S * 1000).toISOString(),
    });
  }

  const last = points[points.length - 1];
  return {
    incident: {
      status: 'ACTIVE',
      created_at: new Date(startMs).toISOString(),
      updated_at: last.recorded_at,
      trigger_label: 'Power button pressed 3 times',
      address: '100 Feet Road, Indiranagar, Bengaluru 560038',
      battery: last.battery_percentage,
      first_name: 'Priya',
    },
    breadcrumbs: points.slice(-360),
  };
}
