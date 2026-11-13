/**
 * Geometry and illustrative circle for the dot-matrix signal globe.
 *
 * Pure data and maths: no three.js, no DOM. The server renders the static
 * poster from these functions and the client builds buffers from the same
 * numbers, so both show the same planet.
 *
 * The circle below is illustrative demonstration material, not contacts or
 * locations held by the app. The globe labels it as such on screen.
 */

import { landDots, toVector } from './globe-land';

export interface GlobePlace {
  /** Short display name. */
  label: string;
  city: string;
  /** Degrees, -90 to 90. */
  lat: number;
  /** Degrees, -180 to 180. */
  lon: number;
}

export interface GuardianPlace extends GlobePlace {
  id: string;
  /** Relationship rather than a fabricated personal name. */
  relation: string;
}

/** Where the alert starts. Bengaluru is the project's own city. */
export const ORIGIN: GlobePlace = {
  label: 'You',
  city: 'Bengaluru',
  lat: 12.97,
  lon: 77.59,
};

/**
 * Five illustrative guardians. Domestic and overseas on purpose: a real circle
 * is rarely in one city, and the mix gives the arcs visibly different lengths.
 */
export const GUARDIANS: readonly GuardianPlace[] = [
  { id: 'sister', relation: 'Sister', label: 'Sister', city: 'Mumbai', lat: 19.08, lon: 72.88 },
  { id: 'parents', relation: 'Parents', label: 'Parents', city: 'Delhi', lat: 28.61, lon: 77.21 },
  { id: 'friend', relation: 'Closest friend', label: 'Closest friend', city: 'Chennai', lat: 13.08, lon: 80.27 },
  { id: 'cousin', relation: 'Cousin', label: 'Cousin', city: 'Dubai', lat: 25.2, lon: 55.27 },
  { id: 'uncle', relation: 'Uncle', label: 'Uncle', city: 'Singapore', lat: 1.35, lon: 103.82 },
];

export type Vector3 = readonly [number, number, number];

/** Unit vector for a place on the sphere. */
export function placeVector(place: GlobePlace): Vector3 {
  return toVector(place.lat, place.lon);
}

/** The spin, in degrees, that brings a longitude to face the camera. */
export function spinToFace(lon: number): number {
  return -lon;
}

/**
 * Every land dot as a flat unit-vector buffer, ready for a BufferGeometry
 * position attribute. Scale by the globe radius in the scene.
 */
export function landDotVectors(): Float32Array {
  const dots = landDots();
  const out = new Float32Array(dots.length * 3);
  for (let i = 0; i < dots.length; i += 1) {
    const [x, y, z] = toVector(dots[i].lat, dots[i].lon);
    out[i * 3] = x;
    out[i * 3 + 1] = y;
    out[i * 3 + 2] = z;
  }
  return out;
}

/**
 * Points along a great-circle-ish arc between two places, lifted off the
 * surface at its midpoint so it reads as a signal hop rather than a border.
 * Returns a flat xyz buffer on the unit sphere; scale by the globe radius.
 */
export function arcVectors(from: GlobePlace, to: GlobePlace, segments = 48, lift = 0.26): Float32Array {
  const a = placeVector(from);
  const b = placeVector(to);
  const out = new Float32Array((segments + 1) * 3);

  // Angle between the endpoints decides how high the arc climbs. The constant
  // term matters: every guardian in this circle is within ~30 degrees of
  // Bengaluru, so a purely spread-scaled lift would leave each arc lying flat
  // on the surface, reading as a border rather than a hop.
  const dot = Math.min(1, Math.max(-1, a[0] * b[0] + a[1] * b[1] + a[2] * b[2]));
  const spread = Math.acos(dot) / Math.PI; // 0 adjacent, 1 antipodal
  const height = 1 + lift * (0.4 + 0.6 * spread);

  for (let i = 0; i <= segments; i += 1) {
    const t = i / segments;
    // Normalised linear blend keeps the path on the sphere; the sine term
    // raises the middle without moving the endpoints.
    const x = a[0] + (b[0] - a[0]) * t;
    const y = a[1] + (b[1] - a[1]) * t;
    const z = a[2] + (b[2] - a[2]) * t;
    const length = Math.hypot(x, y, z) || 1;
    const radius = 1 + (height - 1) * Math.sin(Math.PI * t);
    out[i * 3] = (x / length) * radius;
    out[i * 3 + 1] = (y / length) * radius;
    out[i * 3 + 2] = (z / length) * radius;
  }
  return out;
}

export interface Projected {
  /** -1 to 1, left to right. */
  x: number;
  /** -1 to 1, bottom to top. */
  y: number;
  /** Positive faces the camera; negative is the far side. */
  z: number;
}

/**
 * Orthographic projection of a place, matching the poster and the scene's
 * resting orientation. `spin` rotates about the pole, `tilt` leans the north
 * pole toward the viewer.
 */
export function projectUnit(lat: number, lon: number, spin: number, tilt: number): Projected {
  const [x, y, z] = toVector(lat, lon);
  const s = (spin * Math.PI) / 180;
  const t = (tilt * Math.PI) / 180;

  // Yaw about Y.
  const xs = x * Math.cos(s) + z * Math.sin(s);
  const zs = -x * Math.sin(s) + z * Math.cos(s);
  // Pitch about X.
  const ys = y * Math.cos(t) - zs * Math.sin(t);
  const zt = y * Math.sin(t) + zs * Math.cos(t);

  return { x: xs, y: ys, z: zt };
}

/**
 * Half-extent of the orthographic view, in globe radii. The WebGL camera, the
 * static poster and the CSS limb all derive from this, so they cannot drift
 * apart: a marker positioned by the DOM lands exactly where WebGL draws it.
 * Sized to clear the tallest arc (about 1.17 radii) and the selected marker's
 * label, without leaving the sphere small in a sea of margin.
 */
export const VIEW_HALF = 1.24;

/** Globe radius inside the poster's 0..100 viewBox. */
export const POSTER_RADIUS = 50 / VIEW_HALF;

/** Inset, in percent, that lands a CSS ring exactly on the sphere's edge. */
export const LIMB_INSET = ((1 - 1 / VIEW_HALF) / 2) * 100;

/** Resting orientation: Bengaluru centred, north leaning slightly forward. */
export const POSTER_SPIN = spinToFace(ORIGIN.lon);
export const POSTER_TILT = 16;

/**
 * SVG path data for the static poster, in a 0..100 box.
 *
 * Every dot is a zero-length segment, so one path with `stroke-linecap: round`
 * draws the whole visible hemisphere: the no-JS fallback is a single element
 * rather than a thousand circles.
 *
 * Every point is used, never every nth. Subsampling a Fibonacci spiral by a
 * fixed step multiplies its golden angle by that step, and the product aliases
 * into a small number of turns per revolution: step 3 collapses 2.4 rad to
 * about 0.92 rad, which draws visible spiral arms instead of even coverage.
 * Back-face culling already halves the output, and the digits compress well.
 */
export function posterPath(spin = POSTER_SPIN, tilt = POSTER_TILT): string {
  const dots = landDots();
  const radius = POSTER_RADIUS;
  const parts: string[] = [];

  for (let i = 0; i < dots.length; i += 1) {
    const { x, y, z } = projectUnit(dots[i].lat, dots[i].lon, spin, tilt);
    if (z <= 0.04) continue; // keep the poster to the visible face
    const px = Math.round((50 + x * radius) * 10) / 10;
    const py = Math.round((50 - y * radius) * 10) / 10;
    parts.push(`M${px},${py}h0`);
  }
  return parts.join('');
}

/**
 * Poster dot diameter, in viewBox units, matched to what WebGL draws so the
 * fallback and the live scene read as the same object.
 */
export const POSTER_DOT = 0.52;

/** Screen-space poster position for a place, in the same 0..100 box. */
export function posterPoint(place: GlobePlace, spin = POSTER_SPIN, tilt = POSTER_TILT) {
  const { x, y, z } = projectUnit(place.lat, place.lon, spin, tilt);
  return { x: 50 + x * POSTER_RADIUS, y: 50 - y * POSTER_RADIUS, front: z > 0 };
}

/**
 * What a guardian would receive, in the product's own language.
 *
 * Carrier SMS does not depend on an internet request; the tracker link does.
 * Neither is a delivery confirmation, and the wording never implies one.
 */
export function reachDetail(online: boolean): string {
  // Handoff, never transmission: Android takes the message, and nothing in the
  // product can confirm it left the device. The rest of the page is careful
  // about this distinction, so this sentence has to be too.
  return online
    ? 'Carrier SMS is handed to Android and the tracker link updates while they watch it.'
    : 'Carrier SMS is still handed off over cellular. The tracker link waits for internet.';
}
