/** Geo helpers. Pure, no DOM. */

export interface LatLng {
  latitude: number;
  longitude: number;
}

const EARTH_RADIUS_M = 6_371_008.8;
const rad = (d: number) => (d * Math.PI) / 180;

/** Great-circle distance in metres between two points (haversine formula). */
export function haversineM(a: LatLng, b: LatLng): number {
  const dLat = rad(b.latitude - a.latitude);
  const dLon = rad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(rad(a.latitude)) * Math.cos(rad(b.latitude)) * Math.sin(dLon / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Sum of segment lengths along a path, in metres. Fewer than two points gives 0. */
export function totalDistance(points: readonly LatLng[]): number {
  let sum = 0;
  for (let i = 1; i < points.length; i++) sum += haversineM(points[i - 1], points[i]);
  return sum;
}

/** Google Maps URL that drops a pin at the point. */
export function googleMapsUrl(p: LatLng): string {
  return `https://www.google.com/maps/search/?api=1&query=${p.latitude.toFixed(6)},${p.longitude.toFixed(6)}`;
}
