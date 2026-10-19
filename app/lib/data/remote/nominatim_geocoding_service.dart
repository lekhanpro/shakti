import 'package:dio/dio.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import 'overpass_haven_service.dart' show shaktiUserAgent;

/// Reverse geocoding via OpenStreetMap Nominatim. Never throws.
class NominatimGeocodingService implements GeocodingService {
  NominatimGeocodingService({Dio? dio}) : _dio = dio ?? Dio();

  static const endpoint = 'https://nominatim.openstreetmap.org/reverse';
  final Dio _dio;

  @override
  Future<String?> reverse(GeoPoint p) async {
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
      return parse(res.data);
    } catch (_) {
      return null;
    }
  }

  static String? parse(Object? data) {
    if (data is! Map) return null;
    final name = data['display_name'];
    if (name is! String || name.trim().isEmpty) return null;
    final s = name.trim();
    return s.length > 300 ? s.substring(0, 300) : s;
  }
}
