/// Great-circle distance helpers.
///
/// Uses the haversine formula on a spherical Earth of mean radius
/// 6 371 008.8 m (IUGG). Error versus the WGS-84 ellipsoid is under 0.5 %,
/// which is ample for "nearest police station" and 150 m geofences.
library;

import 'dart:math' as math;

import '../entities/geo_point.dart';
import '../entities/safe_haven.dart';

abstract final class Proximity {
  static const double earthRadiusM = 6371008.8;

  static double _rad(double deg) => deg * math.pi / 180;

  /// Distance in metres between [a] and [b].
  static double haversineM(GeoPoint a, GeoPoint b) {
    final dLat = _rad(b.lat - a.lat);
    final dLng = _rad(b.lng - a.lng);
    final s = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusM * math.asin(math.min(1, math.sqrt(s)));
  }

  /// New list of [havens], nearest to [from] first. The input is not mutated.
  static List<SafeHaven> sortByDistance(GeoPoint from, List<SafeHaven> havens) {
    final keyed = [for (final h in havens) (h, haversineM(from, h.point))]
      ..sort((x, y) => x.$2.compareTo(y.$2));
    return [for (final k in keyed) k.$1];
  }

  /// Whether [p] lies within [radiusM] metres of [center] (inclusive).
  static bool within(GeoPoint p, GeoPoint center, double radiusM) =>
      haversineM(p, center) <= radiusM;

  /// "850 m" below 1 km (rounded to the metre), otherwise "1.2 km".
  static String formatDistance(double m) {
    final v = m < 0 ? 0.0 : m;
    final rounded = v.round();
    if (rounded < 1000) return '$rounded m';
    return '${(v / 1000).toStringAsFixed(1)} km';
  }
}
