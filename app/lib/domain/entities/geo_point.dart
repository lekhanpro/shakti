/// Plain latitude/longitude pair. Kept free of map-library types so the
/// domain layer stays pure Dart.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  bool get isValid => lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  String get mapsUrl =>
      'https://maps.google.com/?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

/// A single location sample from the device.
class LocationFix {
  const LocationFix({required this.point, required this.at, this.speedKmh, this.accuracyM});
  final GeoPoint point;
  final DateTime at;
  final double? speedKmh;
  final double? accuracyM;
}
