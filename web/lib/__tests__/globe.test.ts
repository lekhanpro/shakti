import { describe, expect, it } from 'vitest';
import {
  GUARDIANS,
  LIMB_INSET,
  ORIGIN,
  POSTER_RADIUS,
  POSTER_SPIN,
  POSTER_TILT,
  VIEW_HALF,
  arcVectors,
  landDotVectors,
  posterPath,
  posterPoint,
  projectUnit,
  reachDetail,
  spinToFace,
} from '../globe';
import { POINT_COUNT, landDots, toVector } from '../globe-land';

/** Angular distance, in degrees, from a coordinate to the nearest land dot. */
function nearestLandDeg(lat: number, lon: number): number {
  const [x, y, z] = toVector(lat, lon);
  let best = -1;
  for (const dot of landDots()) {
    const [dx, dy, dz] = toVector(dot.lat, dot.lon);
    const d = x * dx + y * dy + z * dz;
    if (d > best) best = d;
  }
  return (Math.acos(Math.min(1, Math.max(-1, best))) * 180) / Math.PI;
}

/**
 * The land mask is baked by scripts/bake-globe-land.py and decoded here. There
 * is no way to run the Python encoder from vitest, so these probes are the
 * agreement test: the decoder has to walk the same Fibonacci spiral in the same
 * order, or the continents land somewhere else entirely.
 */
describe('baked land mask', () => {
  it('decodes the dots the generator reported', () => {
    expect(POINT_COUNT).toBe(13000);
    expect(landDots()).toHaveLength(3712);
  });

  it('memoises, so the hero does not decode twice', () => {
    expect(landDots()).toBe(landDots());
  });

  it('puts land where land is', () => {
    // Dot spacing is about 1.8 degrees, so anything inland resolves well
    // inside 2.5. A decoder that walked the spiral differently would miss.
    expect(nearestLandDeg(12.97, 77.59)).toBeLessThan(2.5); // Bengaluru
    expect(nearestLandDeg(23, 13)).toBeLessThan(2.5); // Sahara
    expect(nearestLandDeg(-3, -60)).toBeLessThan(2.5); // Amazon basin
    expect(nearestLandDeg(65, 100)).toBeLessThan(2.5); // central Siberia
  });

  it('leaves deep ocean empty', () => {
    expect(nearestLandDeg(0, -140)).toBeGreaterThan(2.5); // east Pacific
    expect(nearestLandDeg(30, -40)).toBeGreaterThan(2.5); // mid Atlantic
    expect(nearestLandDeg(-20, 80)).toBeGreaterThan(2.5); // Indian Ocean
  });

  it('emits one unit vector per dot for the points buffer', () => {
    const buffer = landDotVectors();
    expect(buffer).toHaveLength(landDots().length * 3);
    for (let i = 0; i < buffer.length; i += 3 * 97) {
      const length = Math.hypot(buffer[i], buffer[i + 1], buffer[i + 2]);
      expect(length).toBeCloseTo(1, 6);
    }
  });
});

/**
 * projectUnit has to agree with what three.js renders, because the city markers
 * are DOM elements placed from it over a WebGL canvas. If the two disagree, the
 * labels drift off the sphere.
 */
describe('projectUnit', () => {
  it('faces longitude 0 at the camera when the globe is unturned', () => {
    const p = projectUnit(0, 0, 0, 0);
    expect(p.x).toBeCloseTo(0, 6);
    expect(p.y).toBeCloseTo(0, 6);
    expect(p.z).toBeCloseTo(1, 6);
  });

  it('puts the poles at the top and bottom of the frame', () => {
    expect(projectUnit(90, 0, 0, 0).y).toBeCloseTo(1, 6);
    expect(projectUnit(-90, 0, 0, 0).y).toBeCloseTo(-1, 6);
  });

  it('puts a quarter turn of longitude on the limb', () => {
    const p = projectUnit(0, 90, 0, 0);
    expect(p.x).toBeCloseTo(1, 6);
    expect(p.z).toBeCloseTo(0, 6); // edge-on, neither front nor back
  });

  it('keeps every projected point on the unit sphere', () => {
    for (const [lat, lon, spin, tilt] of [
      [12.97, 77.59, -77.59, 16],
      [-33.9, 151.2, 40, -20],
      [64.1, -21.9, 200, 55],
      [0, 180, -180, 0],
    ]) {
      const p = projectUnit(lat, lon, spin, tilt);
      expect(Math.hypot(p.x, p.y, p.z)).toBeCloseTo(1, 6);
    }
  });

  it('composes yaw before pitch, matching the scene graph', () => {
    // The component nests tiltGroup around spinGroup, so spin applies first.
    // Pitch-then-yaw would put this point at roughly (0.5, 0.5, -0.71).
    const p = projectUnit(45, 90, 90, 45);
    expect(p.x).toBeCloseTo(0, 6);
    expect(p.y).toBeCloseTo(1, 6);
    expect(p.z).toBeCloseTo(0, 6);
  });

  it('leans the north pole toward the viewer on positive tilt', () => {
    expect(projectUnit(90, 0, 0, 90).z).toBeCloseTo(1, 6);
  });
});

describe('spinToFace', () => {
  it('brings any longitude round to the camera', () => {
    for (const lon of [0, 77.59, -21.9, 151.2, 180]) {
      expect(projectUnit(0, lon, spinToFace(lon), 0).z).toBeCloseTo(1, 6);
    }
  });

  it('rests with Bengaluru centred and facing out', () => {
    const p = projectUnit(ORIGIN.lat, ORIGIN.lon, POSTER_SPIN, POSTER_TILT);
    expect(p.x).toBeCloseTo(0, 2);
    expect(p.z).toBeGreaterThan(0.99);
  });
});

/**
 * One constant drives the WebGL camera, the SVG poster and the CSS limb ring,
 * so they cannot drift apart. These lock that.
 */
describe('view geometry', () => {
  it('lands the CSS limb ring exactly on the sphere edge', () => {
    expect(50 + POSTER_RADIUS).toBeCloseTo(100 - LIMB_INSET, 10);
  });

  it('places a limb point on that same ring', () => {
    const edge = posterPoint({ label: '', city: '', lat: 0, lon: 90 }, 0, 0);
    expect(edge.x).toBeCloseTo(100 - LIMB_INSET, 6);
  });

  it('separates the near face from the far face', () => {
    const near = posterPoint({ label: '', city: '', lat: 0, lon: 0 }, 0, 0);
    const far = posterPoint({ label: '', city: '', lat: 0, lon: 180 }, 0, 0);
    expect(near.front).toBe(true);
    expect(far.front).toBe(false);
    // A point exactly on the limb is a measure-zero case and resolves either
    // way on floating point, so nothing asserts it: markers there are at their
    // dimmest in both branches.
  });

  it('reports the origin on the front face at rest', () => {
    const point = posterPoint(ORIGIN);
    expect(point.front).toBe(true);
    expect(point.x).toBeCloseTo(50, 1);
  });
});

describe('arcVectors', () => {
  it('starts and ends on the surface, and bows out between', () => {
    const flat = arcVectors(ORIGIN, GUARDIANS[4], 56, 0.24);
    const radiusAt = (i: number) => Math.hypot(flat[i * 3], flat[i * 3 + 1], flat[i * 3 + 2]);
    expect(radiusAt(0)).toBeCloseTo(1, 6);
    expect(radiusAt(56)).toBeCloseTo(1, 6);
    expect(radiusAt(28)).toBeGreaterThan(1.02);
  });

  it('keeps every arc inside the camera, so none clips at the frame', () => {
    // Mirrors the lift the component passes: 0.2 + index * 0.012.
    let tallest = 0;
    GUARDIANS.forEach((place, index) => {
      const flat = arcVectors(ORIGIN, place, 56, 0.2 + index * 0.012);
      for (let i = 0; i < flat.length; i += 3) {
        tallest = Math.max(tallest, Math.hypot(flat[i], flat[i + 1], flat[i + 2]));
      }
    });
    expect(tallest).toBeGreaterThan(1);
    expect(tallest).toBeLessThan(VIEW_HALF);
  });

  it('lifts a long hop higher than a short one', () => {
    const peak = (to: typeof GUARDIANS[number]) => {
      const flat = arcVectors(ORIGIN, to, 48, 0.24);
      const mid = 24 * 3;
      return Math.hypot(flat[mid], flat[mid + 1], flat[mid + 2]);
    };
    const chennai = GUARDIANS.find((g) => g.city === 'Chennai')!;
    const singapore = GUARDIANS.find((g) => g.city === 'Singapore')!;
    expect(peak(singapore)).toBeGreaterThan(peak(chennai));
  });
});

/** The poster is the first paint and the permanent no-WebGL design. */
describe('posterPath', () => {
  const path = posterPath();

  it('draws only the visible hemisphere', () => {
    const drawn = (path.match(/M/g) ?? []).length;
    expect(drawn).toBeGreaterThan(1500);
    expect(drawn).toBeLessThan(landDots().length);
  });

  it('stays inside the viewBox', () => {
    const numbers = [...path.matchAll(/M([-\d.]+),([-\d.]+)/g)];
    expect(numbers.length).toBeGreaterThan(0);
    for (const [, x, y] of numbers) {
      expect(Number(x)).toBeGreaterThanOrEqual(0);
      expect(Number(x)).toBeLessThanOrEqual(100);
      expect(Number(y)).toBeGreaterThanOrEqual(0);
      expect(Number(y)).toBeLessThanOrEqual(100);
    }
  });

  it('turns with the globe', () => {
    expect(posterPath(0, 0)).not.toBe(path);
  });
});

/**
 * Product truth, not copy polish: carrier SMS does not depend on an internet
 * request, so dropping the tracker link must never read as losing the alert.
 */
describe('reachDetail', () => {
  it('says the tracker link updates while a guardian watches it', () => {
    expect(reachDetail(true)).toMatch(/tracker link/i);
  });

  it('describes handoff over cellular with the link queued', () => {
    const offline = reachDetail(false);
    expect(offline).toMatch(/cellular/i);
    expect(offline).toMatch(/waits for internet/i);
    expect(offline).toMatch(/handed off/i);
  });

  it('never claims delivery or transmission either way', () => {
    for (const text of [reachDetail(true), reachDetail(false)]) {
      // "goes out" and "was sent" would assert the message left the device,
      // which Android handoff cannot confirm.
      expect(text).not.toMatch(/delivered|confirm|guaranteed|goes out|was sent/i);
    }
  });
});

/** The five guardians are illustrative demonstration data. */
describe('illustrative circle', () => {
  it('names relationships rather than inventing people', () => {
    for (const place of GUARDIANS) {
      expect(place.relation).toBeTruthy();
      expect(place.label).toBe(place.relation);
    }
  });

  it('mixes domestic and overseas, so the arcs differ in length', () => {
    const indian = GUARDIANS.filter((g) => g.lon > 68 && g.lon < 98 && g.lat > 6 && g.lat < 36);
    expect(indian.length).toBeGreaterThan(0);
    expect(indian.length).toBeLessThan(GUARDIANS.length);
  });

  it('holds coordinates inside the real range', () => {
    for (const place of [ORIGIN, ...GUARDIANS]) {
      expect(Math.abs(place.lat)).toBeLessThanOrEqual(90);
      expect(Math.abs(place.lon)).toBeLessThanOrEqual(180);
    }
  });
});
