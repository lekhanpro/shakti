import 'geo_point.dart';

enum HavenCategory {
  police('POLICE_STATION', 'Police'),
  hospital('HOSPITAL', 'Hospital'),
  pharmacy('PHARMACY_247', 'Pharmacy'),
  shelter('COMMUNITY_SHELTER', 'Shelter');

  const HavenCategory(this.wire, this.label);
  final String wire;
  final String label;

  static HavenCategory fromWire(String v) =>
      HavenCategory.values.firstWhere((e) => e.wire == v, orElse: () => HavenCategory.shelter);
}

/// A verified public place of safety (from OpenStreetMap / Overpass).
class SafeHaven {
  const SafeHaven({
    required this.id,
    required this.name,
    required this.category,
    required this.point,
    this.phone,
    this.address,
    this.open24h = false,
  });

  /// `osm:<type>/<id>`.
  final String id;
  final String name;
  final HavenCategory category;
  final GeoPoint point;
  final String? phone;
  final String? address;
  final bool open24h;

  @override
  bool operator ==(Object other) => other is SafeHaven && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A user-defined place (Home, College, Hostel) used for arrival pings.
class SafePlace {
  const SafePlace({required this.id, required this.name, required this.point, this.radiusM = 150});
  final String id;
  final String name;
  final GeoPoint point;
  final double radiusM;
}

class WalkRoute {
  const WalkRoute({required this.points, required this.distanceM, required this.durationS});
  final List<GeoPoint> points;
  final double distanceM;
  final double durationS;
}
