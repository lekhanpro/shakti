import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/proximity.dart';
import 'package:shakti/domain/entities/entities.dart';

SafeHaven haven(String id, double lat, double lng) =>
    SafeHaven(id: id, name: id, category: HavenCategory.police, point: GeoPoint(lat, lng));

void main() {
  const mgRoad = GeoPoint(12.9756, 77.6050);
  const majestic = GeoPoint(12.9767, 77.5713);

  test('haversine of identical points is 0', () {
    expect(Proximity.haversineM(mgRoad, mgRoad), 0);
  });

  test('haversine MG Road to Majestic is about 3.66 km', () {
    final d = Proximity.haversineM(mgRoad, majestic);
    expect(d, closeTo(3660, 40));
    expect(Proximity.haversineM(majestic, mgRoad), closeTo(d, 1e-6));
  });

  test('one degree of latitude is about 111.2 km', () {
    expect(Proximity.haversineM(const GeoPoint(0, 0), const GeoPoint(1, 0)), closeTo(111195, 50));
  });

  test('sortByDistance orders nearest first and does not mutate input', () {
    final havens = [
      haven('far', 13.05, 77.60),
      haven('near', 12.9760, 77.6052),
      haven('mid', 12.99, 77.60),
    ];
    final sorted = Proximity.sortByDistance(mgRoad, havens);
    expect(sorted.map((h) => h.id), ['near', 'mid', 'far']);
    expect(havens.first.id, 'far');
    expect(Proximity.sortByDistance(mgRoad, const []), isEmpty);
  });

  test('within', () {
    const p = GeoPoint(12.9760, 77.6050); // ~49 m north
    expect(Proximity.within(p, mgRoad, 150), isTrue);
    expect(Proximity.within(p, mgRoad, 30), isFalse);
  });

  test('formatDistance', () {
    expect(Proximity.formatDistance(0), '0 m');
    expect(Proximity.formatDistance(850), '850 m');
    expect(Proximity.formatDistance(849.6), '850 m');
    expect(Proximity.formatDistance(999.7), '1.0 km');
    expect(Proximity.formatDistance(1200), '1.2 km');
    expect(Proximity.formatDistance(15480), '15.5 km');
    expect(Proximity.formatDistance(-5), '0 m');
  });
}
