/// Scores walking routes by how much of their length sits near a safe haven.
///
/// The route is sampled every [SafeRouteScorer.sampleStepM] metres. Each
/// sample takes the weight of the best haven category within the cover
/// radius (police 1.0, hospital 0.8, shelter 0.7, pharmacy 0.6, none 0).
/// The score is the mean over samples, in 0..1. When the shortest candidate
/// length is known, a small penalty (capped at [maxLengthPenalty]) is taken
/// off longer routes so a safer detour still wins but ties go to the shorter.
library;

import 'dart:math' as math;

import '../entities/geo_point.dart';
import '../entities/safe_haven.dart';
import 'proximity.dart';

abstract final class SafeRouteScorer {
  static const double defaultCoverRadiusM = 300;
  static const double sampleStepM = 25;
  static const double maxLengthPenalty = 0.2;

  /// Penalty per unit of relative extra length (0.5 = 50 % longer -> 0.05).
  static const double lengthPenaltyRate = 0.1;

  static double weight(HavenCategory c) => switch (c) {
        HavenCategory.police => 1.0,
        HavenCategory.hospital => 0.8,
        HavenCategory.shelter => 0.7,
        HavenCategory.pharmacy => 0.6,
      };

  static List<GeoPoint> _samples(List<GeoPoint> pts) {
    if (pts.length < 2) return List.of(pts);
    final out = <GeoPoint>[pts.first];
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final n = math.max(1, (Proximity.haversineM(a, b) / sampleStepM).ceil());
      for (var k = 1; k <= n; k++) {
        final f = k / n;
        out.add(GeoPoint(a.lat + (b.lat - a.lat) * f, a.lng + (b.lng - a.lng) * f));
      }
    }
    return out;
  }

  /// Coverage score of [route] in 0..1.
  static double score(
    WalkRoute route,
    List<SafeHaven> havens, {
    double coverRadiusM = defaultCoverRadiusM,
    double? shortestM,
  }) {
    if (route.points.isEmpty || havens.isEmpty) return 0;
    final samples = _samples(route.points);
    var total = 0.0;
    for (final s in samples) {
      var best = 0.0;
      for (final h in havens) {
        final w = weight(h.category);
        if (w > best && Proximity.within(s, h.point, coverRadiusM)) best = w;
      }
      total += best;
    }
    var result = total / samples.length;
    if (shortestM != null && shortestM > 0 && route.distanceM > shortestM) {
      final extra = route.distanceM / shortestM - 1;
      result -= math.min(maxLengthPenalty, extra * lengthPenaltyRate);
    }
    return result.clamp(0.0, 1.0);
  }

  /// Index of the best route, or -1 when [routes] is empty. Ties go to the
  /// shorter route.
  static int bestIndex(
    List<WalkRoute> routes,
    List<SafeHaven> havens, {
    double coverRadiusM = defaultCoverRadiusM,
  }) {
    if (routes.isEmpty) return -1;
    final shortest = routes.map((r) => r.distanceM).reduce(math.min);
    var best = -1;
    var bestScore = double.negativeInfinity;
    for (var i = 0; i < routes.length; i++) {
      final s = score(routes[i], havens, coverRadiusM: coverRadiusM, shortestM: shortest);
      final better = s > bestScore + 1e-9 ||
          ((s - bestScore).abs() <= 1e-9 && routes[i].distanceM < routes[best].distanceM);
      if (better) {
        best = i;
        bestScore = s;
      }
    }
    return best;
  }
}
