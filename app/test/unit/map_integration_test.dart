import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/di/providers.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/domain/services/services.dart';
import 'package:shakti/features/safety_map/application/map_controller.dart';
import 'package:shakti/features/safety_map/presentation/map_basemap.dart';

import '../fakes/fakes.dart';

class _PendingRoute implements RoutingService {
  final result = Completer<Result<List<WalkRoute>>>();
  @override
  Future<Result<List<WalkRoute>>> walkingRoutes(GeoPoint from, GeoPoint to) =>
      result.future;
}

void main() {
  late Fakes f;
  late ProviderContainer c;
  setUp(() {
    f = Fakes();
    c = ProviderContainer(overrides: f.overrides());
  });
  tearDown(() => c.dispose());

  Future<MapController> loaded() async {
    final ctrl = c.read(mapControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    return ctrl;
  }

  test(
    'denied GPS does not query default Bengaluru as nearby places',
    () async {
      f.location.permission = false;
      await loaded();
      final state = c.read(mapControllerProvider);
      expect(state.phase, MapPhase.permissionDenied);
      expect(state.me, isNull);
      expect(state.locationError, isNotNull);
      expect(f.havens.calls, isEmpty);
    },
  );

  test('GPS failure is visible even when permission was granted', () async {
    f.location.error = 'GPS unavailable';
    await loaded();
    final state = c.read(mapControllerProvider);
    expect(state.phase, MapPhase.error);
    expect(state.locationError, contains('Turn on device location'));
    expect(f.havens.calls, isEmpty);
  });

  test(
    'provider failure retains local places with an explicit error',
    () async {
      f.havenCache.havens = List.of(f.havens.havens);
      f.havens.error = 'Overpass unavailable';
      await loaded();
      final state = c.read(mapControllerProvider);
      expect(state.havens, hasLength(2));
      expect(state.fromCache, isTrue);
      expect(state.placesError, isNotNull);
    },
  );

  test('cache from another city is not presented as nearby', () async {
    f.connectivity.online = false;
    f.havenCache.havens = const [
      SafeHaven(
        id: 'far',
        name: 'Distant hospital',
        category: HavenCategory.hospital,
        point: GeoPoint(28.6, 77.2),
      ),
    ];
    await loaded();
    expect(c.read(mapControllerProvider).havens, isEmpty);
    expect(c.read(mapControllerProvider).placesError, contains('offline'));
  });

  test('clearing a route ignores a late network response', () async {
    c.dispose();
    final routing = _PendingRoute();
    c = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(f.location),
        connectivityServiceProvider.overrideWithValue(f.connectivity),
        havenServiceProvider.overrideWithValue(f.havens),
        havenCacheRepositoryProvider.overrideWithValue(f.havenCache),
        routingServiceProvider.overrideWithValue(routing),
      ],
    );
    final ctrl = await loaded();
    final request = ctrl.walkTo(f.havens.havens.first);
    ctrl.clearRoute();
    routing.result.complete(Ok(f.routing.routes));
    await request;
    expect(c.read(mapControllerProvider).bestRoute, isNull);
    expect(c.read(mapControllerProvider).routeTarget, isNull);
    expect(c.read(mapControllerProvider).routeLoading, isFalse);
  });

  test('configured CARTO uses distinct real light and dark tile styles', () {
    expect(
      MapBasemap.url(dark: false, key: 'public-key'),
      contains('/light_all/'),
    );
    expect(
      MapBasemap.url(dark: true, key: 'public-key'),
      contains('/dark_all/'),
    );
    expect(
      MapBasemap.url(dark: false, key: ''),
      startsWith('https://tile.openstreetmap.org/'),
    );
  });
}
