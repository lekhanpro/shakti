import 'package:dio/dio.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'overpass_haven_service.dart' show shaktiUserAgent;
import 'public_request_gate.dart';

/// Walking routes from FOSSGIS's foot-specific OSRM instance.
/// The profile text alone does not select a walking dataset on a car instance.
class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({Dio? dio, this.baseUrl = defaultBaseUrl})
    : _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  static const defaultBaseUrl = 'https://routing.openstreetmap.de/routed-foot';

  final Dio _dio;
  final String baseUrl;
  final _gate = PublicRequestGate();

  static String _coord(GeoPoint p) =>
      '${p.lng.toStringAsFixed(6)},${p.lat.toStringAsFixed(6)}';

  String urlFor(GeoPoint from, GeoPoint to) =>
      '${baseUrl.replaceFirst(RegExp(r"/+$"), "")}/route/v1/foot/${_coord(from)};${_coord(to)}?alternatives=3&overview=full&geometries=geojson';

  @override
  Future<Result<List<WalkRoute>>> walkingRoutes(
    GeoPoint from,
    GeoPoint to,
  ) async {
    try {
      final res = await _gate.run(
        () => _dio.get<Object?>(
          urlFor(from, to),
          options: Options(
            responseType: ResponseType.json,
            headers: {'User-Agent': shaktiUserAgent},
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
          ),
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
      final coords = (r['geometry'] is Map)
          ? (r['geometry'] as Map)['coordinates']
          : null;
      if (coords is! List) continue;
      final points = <GeoPoint>[
        for (final c in coords)
          if (c is List &&
              c.length >= 2 &&
              c[0] is num &&
              c[1] is num &&
              (c[0] as num).isFinite &&
              (c[1] as num).isFinite &&
              (c[0] as num).abs() <= 180 &&
              (c[1] as num).abs() <= 90)
            GeoPoint((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      final distance = r['distance'];
      final duration = r['duration'];
      if (points.length < 2 ||
          distance is! num ||
          duration is! num ||
          !distance.isFinite ||
          !duration.isFinite ||
          distance < 0 ||
          duration < 0) {
        continue;
      }
      out.add(
        WalkRoute(
          points: points,
          distanceM: distance.toDouble(),
          durationS: duration.toDouble(),
        ),
      );
    }
    return out;
  }
}
