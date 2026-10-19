import 'package:dio/dio.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'overpass_haven_service.dart' show shaktiUserAgent;

/// Walking routes (with alternatives) from the public OSRM demo server.
class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({Dio? dio, this.baseUrl = 'https://router.project-osrm.org'}) : _dio = dio ?? Dio();

  final Dio _dio;
  final String baseUrl;

  static String _coord(GeoPoint p) => '${p.lng.toStringAsFixed(6)},${p.lat.toStringAsFixed(6)}';

  String urlFor(GeoPoint from, GeoPoint to) =>
      '$baseUrl/route/v1/foot/${_coord(from)};${_coord(to)}?alternatives=3&overview=full&geometries=geojson';

  @override
  Future<Result<List<WalkRoute>>> walkingRoutes(GeoPoint from, GeoPoint to) async {
    try {
      final res = await _dio.get<Object?>(
        urlFor(from, to),
        options: Options(
          responseType: ResponseType.json,
          headers: {'User-Agent': shaktiUserAgent},
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
        ),
      );
      final routes = parse(res.data);
      return routes.isEmpty ? const Err('No walking route found') : Ok(routes);
    } catch (e) {
      return Err('Routing is unavailable right now', e);
    }
  }

  static List<WalkRoute> parse(Object? data) {
    if (data is! Map || data['code'] != 'Ok') return const [];
    final routes = data['routes'];
    if (routes is! List) return const [];
    final out = <WalkRoute>[];
    for (final r in routes) {
      if (r is! Map) continue;
      final coords = (r['geometry'] is Map) ? (r['geometry'] as Map)['coordinates'] : null;
      if (coords is! List) continue;
      final points = <GeoPoint>[
        for (final c in coords)
          if (c is List && c.length >= 2 && c[0] is num && c[1] is num)
            GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) continue;
      out.add(WalkRoute(
        points: points,
        distanceM: (r['distance'] is num) ? (r['distance'] as num).toDouble() : 0,
        durationS: (r['duration'] is num) ? (r['duration'] as num).toDouble() : 0,
      ));
    }
    return out;
  }
}
