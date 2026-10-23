import 'package:dio/dio.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'overpass_haven_service.dart' show shaktiUserAgent;
import 'public_request_gate.dart';

/// Reverse geocoding via OpenStreetMap Nominatim. Never throws.
class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({Dio? dio})
    : _dio =
          dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 5)));

  static const endpoint = 'https://nominatim.openstreetmap.org/reverse';
  final Dio _dio;
  final _gate = PublicRequestGate();
  final _cache = <String, String>{};

  @override
  Future<String?> reverse(GeoPoint p) async {
    final key = '${p.lat.toStringAsFixed(4)},${p.lng.toStringAsFixed(4)}';
    if (_cache.containsKey(key)) return _cache[key];
    return _gate.run(() async {
      // A concurrent caller may have filled this entry while queued.
      if (_cache.containsKey(key)) return _cache[key];
      try {
        final res = await _dio.get<Object?>(
          endpoint,
          queryParameters: {
            'format': 'jsonv2',
            'lat': p.lat.toStringAsFixed(6),
            'lon': p.lng.toStringAsFixed(6),
            'zoom': 18,
            'addressdetails': 0,
          },
          options: Options(
            responseType: ResponseType.json,
            headers: {'User-Agent': shaktiUserAgent, 'Accept-Language': 'en'},
            receiveTimeout: const Duration(seconds: 8),
            sendTimeout: const Duration(seconds: 8),
          ),
        );
        final address = parse(res.data);
        if (address != null) {
          if (_cache.length >= 128) _cache.remove(_cache.keys.first);
          _cache[key] = address;
        }
        return address;
      } catch (_) {
        return null;
      }
    });
  }

  static String? parse(Object? data) {
    if (data is! Map) return null;
    final name = data['display_name'];
    if (name is! String || name.trim().isEmpty) return null;
    final s = name.trim();
    return s.length > 300 ? s.substring(0, 300) : s;
  }
}
