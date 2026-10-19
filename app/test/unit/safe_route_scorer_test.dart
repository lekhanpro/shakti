import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/safe_route_scorer.dart';
import 'package:shakti/domain/entities/entities.dart';

SafeHaven haven(String id, HavenCategory c, GeoPoint p) =>
    SafeHaven(id: id, name: id, category: c, point: p);

void main() {
  // Two parallel ~1.1 km routes going north, ~1.1 km apart in longitude.
  const a0 = GeoPoint(12.970, 77.600);
  const a1 = GeoPoint(12.980, 77.600);
  const b0 = GeoPoint(12.970, 77.610);
  const b1 = GeoPoint(12.980, 77.610);
  const routeA = WalkRoute(points: [a0, a1], distanceM: 1112, durationS: 800);
  const routeB = WalkRoute(points: [b0, b1], distanceM: 1112, durationS: 800);

  final policeOnA = [
    haven('p1', HavenCategory.police, const GeoPoint(12.9725, 77.600)),
    haven('p2', HavenCategory.police, const GeoPoint(12.9775, 77.600)),
  ];

  test('no havens gives zero', () {
    expect(SafeRouteScorer.score(routeA, const []), 0);
  });

  test('route fully covered by police scores near 1', () {
    expect(SafeRouteScorer.score(routeA, policeOnA), closeTo(1, 0.05));
    expect(SafeRouteScorer.score(routeB, policeOnA), 0);
  });

  test('category weights: police > hospital > shelter > pharmacy', () {
    double s(HavenCategory c) => SafeRouteScorer.score(routeA, [
          haven('x1', c, const GeoPoint(12.9725, 77.600)),
          haven('x2', c, const GeoPoint(12.9775, 77.600)),
        ]);
    final police = s(HavenCategory.police);
    final hospital = s(HavenCategory.hospital);
    final shelter = s(HavenCategory.shelter);
    final pharmacy = s(HavenCategory.pharmacy);
    expect(police, greaterThan(hospital));
    expect(hospital, greaterThan(shelter));
    expect(shelter, greaterThan(pharmacy));
    expect(hospital / police, closeTo(0.8, 0.01));
    expect(pharmacy / police, closeTo(0.6, 0.01));
  });

  test('best category nearby wins for a sample point', () {
    final mixed = [
      ...policeOnA,
      haven('ph', HavenCategory.pharmacy, const GeoPoint(12.9725, 77.600)),
    ];
    expect(SafeRouteScorer.score(routeA, mixed), SafeRouteScorer.score(routeA, policeOnA));
  });

  test('partial coverage is a fraction', () {
    final one = [haven('p', HavenCategory.police, const GeoPoint(12.9725, 77.600))];
    final s = SafeRouteScorer.score(routeA, one);
    expect(s, greaterThan(0.3));
    expect(s, lessThan(0.7));
  });

  test('coverRadius widens coverage', () {
    final one = [haven('p', HavenCategory.police, const GeoPoint(12.975, 77.600))];
    expect(SafeRouteScorer.score(routeA, one, coverRadiusM: 800),
        greaterThan(SafeRouteScorer.score(routeA, one)));
  });

  test('bestIndex picks the covered route', () {
    expect(SafeRouteScorer.bestIndex([routeB, routeA], policeOnA), 1);
    expect(SafeRouteScorer.bestIndex(const [], policeOnA), -1);
  });

  test('with equal coverage, the shorter route wins', () {
    const longA = WalkRoute(points: [a0, a1], distanceM: 2000, durationS: 1500);
    expect(SafeRouteScorer.bestIndex([longA, routeA], policeOnA), 1);
    expect(SafeRouteScorer.bestIndex([longA, routeB], const []), 1);
  });

  test('length penalty is small: a safer detour still wins', () {
    const detourA = WalkRoute(points: [a0, a1], distanceM: 1500, durationS: 1100);
    expect(SafeRouteScorer.bestIndex([routeB, detourA], policeOnA), 1);
  });

  test('explicit shortestM applies the penalty', () {
    final base = SafeRouteScorer.score(routeA, policeOnA);
    final penalised = SafeRouteScorer.score(routeA, policeOnA, shortestM: 800);
    expect(penalised, lessThan(base));
    expect(base - penalised, lessThanOrEqualTo(0.2));
  });

  test('degenerate routes', () {
    const empty = WalkRoute(points: [], distanceM: 0, durationS: 0);
    expect(SafeRouteScorer.score(empty, policeOnA), 0);
    const single = WalkRoute(points: [GeoPoint(12.9725, 77.600)], distanceM: 0, durationS: 0);
    expect(SafeRouteScorer.score(single, policeOnA), 1);
    expect(SafeRouteScorer.bestIndex([empty, single], policeOnA), 1);
  });
}
