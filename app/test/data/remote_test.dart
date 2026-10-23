import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/data/remote/nominatim_geocoding_service.dart';
import 'package:shakti/data/remote/osrm_routing_service.dart';
import 'package:shakti/data/remote/overpass_haven_service.dart';
import 'package:shakti/domain/entities/entities.dart';

/// Answers each request with [handler]; records every request.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions o, String body) handler;
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : (await requestStream.toList()).expand((e) => e).toList();
    final body = utf8.decode(bytes);
    requests.add(o);
    bodies.add(body);
    return handler(o, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody json(Object data, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Dio dioWith(FakeAdapter a) => Dio()..httpClientAdapter = a;

const _overpassFixture = {
  'version': 0.6,
  'generator': 'Overpass API 0.7.62',
  'elements': [
    {
      'type': 'node',
      'id': 123,
      'lat': 12.9763,
      'lon': 77.5929,
      'tags': {
        'amenity': 'police',
        'name': 'Cubbon Park Police Station',
        'phone': '+91 80 2294 2591',
        'addr:housenumber': '1',
        'addr:street': 'Kasturba Road',
        'addr:city': 'Bengaluru',
        'addr:postcode': '560001',
      },
    },
    {
      'type': 'way',
      'id': 456,
      'center': {'lat': 12.9830, 'lon': 77.6050},
      'nodes': [1, 2, 3],
      'tags': {
        'amenity': 'hospital',
        'name': 'Bowring Hospital',
        'contact:phone': '080 2559 1325',
      },
    },
    {
      'type': 'node',
      'id': 789,
      'lat': 12.97,
      'lon': 77.59,
      'tags': {
        'amenity': 'pharmacy',
        'opening_hours': '24/7',
        'addr:full': 'MG Road, Bengaluru',
      },
    },
    {
      'type': 'node',
      'id': 790,
      'lat': 12.96,
      'lon': 77.58,
      'tags': {
        'amenity': 'social_facility',
        'social_facility': 'shelter',
        'name': ' ',
      },
    },
    // Duplicate, missing coordinates, unknown amenity, garbage: all skipped.
    {
      'type': 'node',
      'id': 123,
      'lat': 1,
      'lon': 1,
      'tags': {'amenity': 'police'},
    },
    {
      'type': 'way',
      'id': 999,
      'tags': {'amenity': 'police'},
    },
    {
      'type': 'node',
      'id': 1000,
      'lat': 1,
      'lon': 1,
      'tags': {'amenity': 'cafe'},
    },
    'garbage',
  ],
};

void main() {
  group('OverpassHavenService', () {
    test('buildQuery covers every category as nodes and ways with out center', () {
      final q = OverpassHavenService.buildQuery(
        const GeoPoint(12.9716, 77.5946),
        2500,
      );
      expect(q, startsWith('[out:json][timeout:20];'));
      const around = '(around:2500,12.971600,77.594600)';
      for (final kind in ['node', 'way', 'relation']) {
        expect(q, contains('$kind["amenity"="police"]$around;'));
        expect(q, contains('$kind["amenity"="hospital"]$around;'));
        expect(
          q,
          contains(
            '$kind["amenity"="pharmacy"]["opening_hours"="24/7"]$around;',
          ),
        );
        expect(
          q,
          contains(
            '$kind["amenity"="social_facility"]["social_facility"="shelter"]$around;',
          ),
        );
      }
      expect(q, contains('out center'));
    });

    test('parse maps OSM elements into havens', () {
      final h = OverpassHavenService.parse(_overpassFixture);
      expect(h.map((e) => e.id), [
        'osm:node/123',
        'osm:way/456',
        'osm:node/789',
        'osm:node/790',
      ]);

      final police = h[0];
      expect(police.name, 'Cubbon Park Police Station');
      expect(police.category, HavenCategory.police);
      expect(police.point, const GeoPoint(12.9763, 77.5929));
      expect(police.phone, '+91 80 2294 2591');
      expect(police.address, '1 Kasturba Road, Bengaluru, 560001');
      expect(
        police.open24h,
        isFalse,
      ); // Opening hours must be explicitly mapped.

      final hospital = h[1];
      expect(hospital.point, const GeoPoint(12.9830, 77.6050));
      expect(hospital.phone, '080 2559 1325');
      expect(hospital.address, isNull);

      final pharmacy = h[2];
      expect(pharmacy.name, 'Pharmacy'); // label fallback
      expect(pharmacy.open24h, isTrue);
      expect(pharmacy.address, 'MG Road, Bengaluru');

      expect(h[3].name, 'Shelter');
      expect(h[3].category, HavenCategory.shelter);
      expect(OverpassHavenService.parse(const {'elements': 'x'}), isEmpty);
    });

    test('nearby posts the query with a User-Agent and parses', () async {
      final a = FakeAdapter((o, _) => json(_overpassFixture));
      final r = await OverpassHavenService(dio: dioWith(a))
          .nearby(const GeoPoint(12.97, 77.59), radiusM: 1000);
      expect(r.valueOrNull, hasLength(4));
      expect(
        a.requests.single.uri.toString(),
        OverpassHavenService.primaryEndpoint,
      );
      expect(a.requests.single.method, 'POST');
      expect(a.requests.single.headers['User-Agent'], contains('Shakti'));
      expect(a.requests.single.receiveTimeout, const Duration(seconds: 20));
      expect(
        Uri.splitQueryString(a.bodies.single)['data'],
        contains('around:1000'),
      );
    });

    test('falls back to the mirror when the primary fails', () async {
      final a = FakeAdapter(
        (o, _) => o.uri.host == 'overpass-api.de'
            ? ResponseBody.fromString('busy', 504)
            : json(_overpassFixture),
      );
      final r = await OverpassHavenService(dio: dioWith(a))
          .nearby(const GeoPoint(12.97, 77.59));
      expect(r.isOk, isTrue);
      expect(a.requests.map((e) => e.uri.host), [
        'overpass-api.de',
        'overpass.kumi.systems',
      ]);
    });

    test('returns Err when every endpoint fails', () async {
      final a = FakeAdapter((o, _) => ResponseBody.fromString('no', 500));
      final r = await OverpassHavenService(dio: dioWith(a))
          .nearby(const GeoPoint(1, 2));
      expect(r, isA<Err<List<SafeHaven>>>());
      final b = FakeAdapter((o, _) => json(['not', 'a', 'map']));
      expect(
        (await OverpassHavenService(dio: dioWith(b))
                .nearby(const GeoPoint(1, 2)))
            .isOk,
        isFalse,
      );
    });

    test(
      'Overpass timeout remarks fail over rather than clear saved places',
      () async {
        final a = FakeAdapter(
          (o, _) => o.uri.host == 'overpass-api.de'
              ? json({
                  'remark': 'runtime error: Query timed out',
                  'elements': [],
                })
              : json(_overpassFixture),
        );
        final result = await OverpassHavenService(dio: dioWith(a))
            .nearby(const GeoPoint(12.97, 77.59));
        expect(result.valueOrNull, hasLength(4));
        expect(a.requests, hasLength(2));
      },
    );
  });

  group('NominatimGeocodingService', () {
    test(
      'reuses an address for repeated fixes in the same small area',
      () async {
        final a = FakeAdapter(
          (o, _) => json({'display_name': 'Public test address'}),
        );
        final service = NominatimGeocodingService(dio: dioWith(a));
        expect(
          await service.reverse(const GeoPoint(12.97, 77.59)),
          'Public test address',
        );
        expect(
          await service.reverse(const GeoPoint(12.970001, 77.590001)),
          'Public test address',
        );
        expect(a.requests, hasLength(1));
      },
    );
    test('returns display_name and sends a User-Agent', () async {
      final a = FakeAdapter(
        (o, _) => json({
          'display_name': ' MG Road, Bengaluru, Karnataka ',
          'lat': '12.97',
        }),
      );
      final addr = await NominatimGeocodingService(dio: dioWith(a))
          .reverse(const GeoPoint(12.97, 77.59));
      expect(addr, 'MG Road, Bengaluru, Karnataka');
      final req = a.requests.single;
      expect(req.uri.path, '/reverse');
      expect(req.uri.queryParameters['lat'], '12.970000');
      expect(req.uri.queryParameters['lon'], '77.590000');
      expect(req.headers['User-Agent'], contains('Shakti'));
    });

    test('null on error or unexpected body, truncates long names', () async {
      expect(
        await NominatimGeocodingService(
          dio: dioWith(FakeAdapter((o, _) => json({'error': 'x'}))),
        ).reverse(const GeoPoint(1, 2)),
        isNull,
      );
      expect(
        await NominatimGeocodingService(
          dio: dioWith(FakeAdapter((o, _) => ResponseBody.fromString('', 500))),
        ).reverse(const GeoPoint(1, 2)),
        isNull,
      );
      expect(NominatimGeocodingService.parse('x'), isNull);
      expect(
        NominatimGeocodingService.parse({'display_name': 'a' * 400})!.length,
        300,
      );
    });
  });

  group('OsrmRoutingService', () {
    const from = GeoPoint(12.9716, 77.5946);
    const to = GeoPoint(12.9763, 77.5929);

    test('builds the foot URL and parses GeoJSON routes', () async {
      final a = FakeAdapter(
        (o, _) => json({
          'code': 'Ok',
          'routes': [
            {
              'distance': 612.4,
              'duration': 441.2,
              'geometry': {
                'type': 'LineString',
                'coordinates': [
                  [77.5946, 12.9716],
                  [77.5935, 12.9740],
                  [77.5929, 12.9763],
                ],
              },
            },
            {
              'distance': 700,
              'duration': 500,
              'geometry': {
                'coordinates': [
                  [77.5946, 12.9716],
                  [77.5929, 12.9763],
                ],
              },
            },
            {
              'distance': 1,
              'geometry': {
                'coordinates': [
                  [1, 2],
                ],
              },
            }, // too short
          ],
        }),
      );
      final svc = OsrmRoutingService(dio: dioWith(a));
      expect(
        svc.urlFor(from, to),
        'https://routing.openstreetmap.de/routed-foot/route/v1/foot/77.594600,12.971600;77.592900,12.976300?alternatives=3&overview=full&geometries=geojson',
      );
      final routes = (await svc.walkingRoutes(from, to)).valueOrNull!;
      expect(routes, hasLength(2));
      expect(routes.first.distanceM, 612.4);
      expect(routes.first.durationS, 441.2);
      expect(routes.first.points.first, from);
      expect(routes.first.points.last, to);
      expect(
        a.requests.single.uri.path,
        '/routed-foot/route/v1/foot/77.594600,12.971600;77.592900,12.976300',
      );
      expect(a.requests.single.uri.queryParameters['alternatives'], '3');
    });

    test('Err on NoRoute and on HTTP failure', () async {
      final none = OsrmRoutingService(
        dio: dioWith(
          FakeAdapter((o, _) => json({'code': 'NoRoute', 'routes': []})),
        ),
      );
      expect((await none.walkingRoutes(from, to)).isOk, isFalse);
      final down = OsrmRoutingService(
        dio: dioWith(FakeAdapter((o, _) => ResponseBody.fromString('x', 503))),
      );
      expect((await down.walkingRoutes(from, to)).isOk, isFalse);
      expect(OsrmRoutingService.parse(null), isEmpty);
      expect(OsrmRoutingService.parse({'code': 'Ok', 'routes': 'x'}), isEmpty);
    });

    test(
      'rejects routes with unknown duration instead of displaying zero minutes',
      () {
        expect(
          OsrmRoutingService.parse({
            'code': 'Ok',
            'routes': [
              {
                'distance': 700,
                'geometry': {
                  'coordinates': [
                    [77.59, 12.97],
                    [77.60, 12.98],
                  ],
                },
              },
            ],
          }),
          isEmpty,
        );
      },
    );
  });
}
