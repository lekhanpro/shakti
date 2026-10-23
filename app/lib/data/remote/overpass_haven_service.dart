import 'package:dio/dio.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';

const shaktiUserAgent = 'Shakti/1.0 (VTU Project Shakti; personal safety app)';

/// Finds police stations, hospitals, 24/7 pharmacies and shelters near a
/// point via the OpenStreetMap Overpass API.
class OverpassHavenService implements HavenService {
  OverpassHavenService({Dio? dio, List<String>? endpoints})
    : _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8))),
      _endpoints = endpoints ?? const [primaryEndpoint, mirrorEndpoint];

  static const primaryEndpoint = 'https://overpass-api.de/api/interpreter';
  static const mirrorEndpoint = 'https://overpass.kumi.systems/api/interpreter';
  static const timeout = Duration(seconds: 20);

  final Dio _dio;
  final List<String> _endpoints;

  /// Overpass QL for every haven category around [c] within [radiusM].
  static String buildQuery(GeoPoint c, double radiusM) {
    final around =
        '(around:${radiusM.round()},${c.lat.toStringAsFixed(6)},${c.lng.toStringAsFixed(6)})';
    const filters = [
      '["amenity"="police"]',
      '["amenity"="hospital"]',
      '["amenity"="pharmacy"]["opening_hours"="24/7"]',
      '["amenity"="social_facility"]["social_facility"="shelter"]',
    ];
    final body = StringBuffer();
    for (final f in filters) {
      body.writeln('  node$f$around;');
      body.writeln('  way$f$around;');
      body.writeln('  relation$f$around;');
    }
    return '[out:json][timeout:20];\n(\n$body);\nout center tags;';
  }

  @override
  Future<Result<List<SafeHaven>>> nearby(
    GeoPoint center, {
    double radiusM = 5000,
  }) async {
    final query = buildQuery(center, radiusM);
    Object? lastError;
    for (final url in _endpoints) {
      try {
        final res = await _dio.post<Object?>(
          url,
          data: {'data': query},
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
            headers: {'User-Agent': shaktiUserAgent},
            sendTimeout: timeout,
            receiveTimeout: timeout,
          ),
        );
        final data = res.data;
        if (data is Map && data['elements'] is List && data['remark'] == null) {
          return Ok(parse(data.cast<String, Object?>()));
        }
        lastError = 'Unexpected response';
      } catch (e) {
        lastError = e;
      }
    }
    return Err('Could not load nearby safe places', lastError);
  }

  /// Parses an Overpass JSON response into havens (deduplicated by id).
  static List<SafeHaven> parse(Map<String, Object?> json) {
    final elements = json['elements'];
    if (elements is! List) return const [];
    final seen = <String>{};
    final out = <SafeHaven>[];
    for (final raw in elements) {
      if (raw is! Map) continue;
      final e = raw.cast<String, Object?>();
      final h = _parseElement(e);
      if (h != null && seen.add(h.id)) out.add(h);
    }
    return out;
  }

  static SafeHaven? _parseElement(Map<String, Object?> e) {
    final type = e['type'];
    final id = e['id'];
    if (type is! String || id is! num) return null;
    final tags = (e['tags'] is Map
        ? (e['tags'] as Map).cast<String, Object?>()
        : const <String, Object?>{});

    double? lat, lng;
    if (e['lat'] is num && e['lon'] is num) {
      lat = (e['lat'] as num).toDouble();
      lng = (e['lon'] as num).toDouble();
    } else if (e['center'] is Map) {
      final c = (e['center'] as Map).cast<String, Object?>();
      if (c['lat'] is num && c['lon'] is num) {
        lat = (c['lat'] as num).toDouble();
        lng = (c['lon'] as num).toDouble();
      }
    }
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180) {
      return null;
    }

    final category = _category(tags);
    if (category == null) return null;

    String? tag(String k) {
      final v = tags[k];
      return v is String && v.trim().isNotEmpty ? v.trim() : null;
    }

    final opening = tag('opening_hours');
    return SafeHaven(
      id: 'osm:$type/${id.toInt()}',
      name: tag('name') ?? tag('name:en') ?? category.label,
      category: category,
      point: GeoPoint(lat, lng),
      phone: tag('phone') ?? tag('contact:phone'),
      address: _address(tag),
      open24h: opening == '24/7',
    );
  }

  static HavenCategory? _category(Map<String, Object?> tags) =>
      switch (tags['amenity']) {
        'police' => HavenCategory.police,
        'hospital' => HavenCategory.hospital,
        'pharmacy' => HavenCategory.pharmacy,
        'social_facility' => HavenCategory.shelter,
        _ => null,
      };

  static String? _address(String? Function(String) tag) {
    final full = tag('addr:full');
    if (full != null) return full;
    final street = [
      tag('addr:housenumber'),
      tag('addr:street'),
    ].whereType<String>().join(' ');
    final parts = [
      if (street.isNotEmpty) street,
      tag('addr:suburb'),
      tag('addr:city'),
      tag('addr:postcode'),
    ].whereType<String>().toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
}
