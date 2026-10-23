import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../../../domain/engines/proximity.dart';
import '../../../domain/engines/safe_route_scorer.dart';
import '../../../domain/entities/entities.dart';

enum MapPhase { loading, ready, permissionDenied, error }

/// Default centre (Bengaluru) used when no fix is available.
const fallbackCenter = GeoPoint(12.9716, 77.5946);

/// A haven counts as "on the route" within this distance of any route vertex.
const routeCoverM = 200.0;

class MapState {
  const MapState({
    this.phase = MapPhase.loading,
    this.me,
    this.havens = const [],
    this.fromCache = false,
    this.filters = const {...HavenCategory.values},
    this.routeTarget,
    this.routes = const [],
    this.bestIndex = -1,
    this.routeLoading = false,
    this.routeError,
    this.safePlacesOnRoute = 0,
    this.locationError,
    this.placesError,
  });

  final MapPhase phase;
  final GeoPoint? me;

  /// Sorted nearest-first when [me] is known.
  final List<SafeHaven> havens;

  /// True when [havens] came from the offline cache.
  final bool fromCache;
  final Set<HavenCategory> filters;
  final SafeHaven? routeTarget;
  final List<WalkRoute> routes;
  final int bestIndex;
  final bool routeLoading;
  final String? routeError;
  final int safePlacesOnRoute;
  final String? locationError;
  final String? placesError;

  GeoPoint get center =>
      me ?? (havens.isEmpty ? fallbackCenter : havens.first.point);

  List<SafeHaven> get visible => [
    for (final h in havens)
      if (filters.contains(h.category)) h,
  ];

  WalkRoute? get bestRoute =>
      bestIndex >= 0 && bestIndex < routes.length ? routes[bestIndex] : null;

  double? distanceTo(SafeHaven h) =>
      me == null ? null : Proximity.haversineM(me!, h.point);

  MapState copyWith({
    MapPhase? phase,
    GeoPoint? me,
    List<SafeHaven>? havens,
    bool? fromCache,
    Set<HavenCategory>? filters,
    SafeHaven? routeTarget,
    bool clearRoute = false,
    List<WalkRoute>? routes,
    int? bestIndex,
    bool? routeLoading,
    String? routeError,
    bool clearRouteError = false,
    int? safePlacesOnRoute,
  }) => MapState(
    phase: phase ?? this.phase,
    me: me ?? this.me,
    havens: havens ?? this.havens,
    fromCache: fromCache ?? this.fromCache,
    filters: filters ?? this.filters,
    routeTarget: clearRoute ? null : (routeTarget ?? this.routeTarget),
    routes: clearRoute ? const [] : (routes ?? this.routes),
    bestIndex: clearRoute ? -1 : (bestIndex ?? this.bestIndex),
    routeLoading: routeLoading ?? this.routeLoading,
    routeError: clearRouteError || clearRoute
        ? null
        : (routeError ?? this.routeError),
    safePlacesOnRoute: clearRoute
        ? 0
        : (safePlacesOnRoute ?? this.safePlacesOnRoute),
    locationError: locationError,
    placesError: placesError,
  );
}

/// Loads nearby havens (network first, offline cache as fallback) and scores
/// walking routes by how many havens they pass.
class MapController extends Notifier<MapState> {
  int _loadVersion = 0;
  int _routeVersion = 0;

  @override
  MapState build() {
    Future.microtask(load);
    return const MapState();
  }

  Future<void> load() async {
    final version = ++_loadVersion;
    ++_routeVersion;
    state = state.copyWith(phase: MapPhase.loading);
    final location = ref.read(locationServiceProvider);
    final connectivity = ref.read(connectivityServiceProvider);
    final havenService = ref.read(havenServiceProvider);
    final cache = ref.read(havenCacheRepositoryProvider);

    final granted = await _try(() => location.ensurePermission(), false);
    if (!ref.mounted || version != _loadVersion) return;
    GeoPoint? me;
    String? locationError;
    if (granted) {
      final fix = await _try<Result<LocationFix>>(
        () => location.currentFix(),
        const Err('Location unavailable'),
      );
      me = fix.valueOrNull?.point;
      if (me == null) {
        locationError =
            'Could not get your location. Turn on device location and retry.';
      }
    } else {
      locationError = 'Location permission is needed for nearby places and walking routes. Allow it in Android settings, then retry.';
    }
    if (!ref.mounted || version != _loadVersion) return;

    final online = await _try(() => connectivity.isOnline(), true);
    List<SafeHaven>? fresh;
    String? placesError;
    // Never query an arbitrary default city and call it "near you".
    if (online && me != null) {
      final res = await _try<Result<List<SafeHaven>>>(
        () => havenService.nearby(me!),
        const Err('Network error'),
      );
      fresh = res.valueOrNull;
      if (fresh == null) {
        placesError =
            'Nearby places could not load. Check your connection and retry.';
      }
    } else if (!online) {
      placesError = 'You are offline. Saved places are available; map tiles and new routes need internet.';
    }
    if (!ref.mounted || version != _loadVersion) return;

    List<SafeHaven> havens;
    var fromCache = false;
    if (fresh != null) {
      havens = fresh;
      unawaited(_try(() => cache.replaceAll(fresh!), null));
    } else {
      havens = await _try(() => cache.cached(), const <SafeHaven>[]);
      fromCache = true;
    }
    if (!ref.mounted || version != _loadVersion) return;
    if (me != null) {
      havens = Proximity.sortByDistance(
        me,
        havens.where((h) => Proximity.within(me!, h.point, 5000)).toList(),
      );
    }

    state = MapState(
      phase: !granted
          ? MapPhase.permissionDenied
          : me == null || (placesError != null && havens.isEmpty)
          ? MapPhase.error
          : MapPhase.ready,
      me: me,
      havens: havens,
      fromCache: fromCache,
      filters: state.filters,
      locationError: locationError,
      placesError: placesError,
    );
  }

  void toggleFilter(HavenCategory c) {
    final next = {...state.filters};
    if (!next.remove(c)) next.add(c);
    state = state.copyWith(filters: next);
  }

  void clearRoute() {
    ++_routeVersion;
    state = state.copyWith(clearRoute: true, routeLoading: false);
  }

  /// Fetches walking alternatives to [target] and picks the safest.
  Future<void> walkTo(SafeHaven target) async {
    final version = ++_routeVersion;
    final me = state.me;
    if (me == null) {
      state = state.copyWith(clearRoute: true, routeLoading: false);
      state = state.copyWith(
        routeTarget: target,
        routeError: 'Turn on location to plan a walking route.',
      );
      return;
    }
    state = state.copyWith(clearRoute: true);
    state = state.copyWith(routeTarget: target, routeLoading: true);
    final res = await _try<Result<List<WalkRoute>>>(
      () => ref.read(routingServiceProvider).walkingRoutes(me, target.point),
      const Err('Routing failed'),
    );
    if (!ref.mounted || version != _routeVersion) return;
    switch (res) {
      case Ok(:final value) when value.isNotEmpty:
        final best = SafeRouteScorer.bestIndex(value, state.havens);
        final idx = best < 0 ? 0 : best;
        state = state.copyWith(
          routes: value,
          bestIndex: idx,
          routeLoading: false,
          safePlacesOnRoute: countOnRoute(value[idx], state.havens),
        );
      case Ok():
        state = state.copyWith(
          routeLoading: false,
          routeError: 'No walking route found.',
        );
      case Err():
        state = state.copyWith(
          routeLoading: false,
          routeError: 'Could not load a route. Check your connection.',
        );
    }
  }

  static int countOnRoute(WalkRoute r, List<SafeHaven> havens) => havens
      .where(
        (h) => r.points.any((p) => Proximity.within(h.point, p, routeCoverM)),
      )
      .length;

  Future<T> _try<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapState>(
  MapController.new,
);
