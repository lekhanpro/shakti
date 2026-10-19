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

  GeoPoint get center => me ?? fallbackCenter;

  List<SafeHaven> get visible => [for (final h in havens) if (filters.contains(h.category)) h];

  WalkRoute? get bestRoute => bestIndex >= 0 && bestIndex < routes.length ? routes[bestIndex] : null;

  double? distanceTo(SafeHaven h) => me == null ? null : Proximity.haversineM(me!, h.point);

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
  }) =>
      MapState(
        phase: phase ?? this.phase,
        me: me ?? this.me,
        havens: havens ?? this.havens,
        fromCache: fromCache ?? this.fromCache,
        filters: filters ?? this.filters,
        routeTarget: clearRoute ? null : (routeTarget ?? this.routeTarget),
        routes: clearRoute ? const [] : (routes ?? this.routes),
        bestIndex: clearRoute ? -1 : (bestIndex ?? this.bestIndex),
        routeLoading: routeLoading ?? this.routeLoading,
        routeError: clearRouteError || clearRoute ? null : (routeError ?? this.routeError),
        safePlacesOnRoute: clearRoute ? 0 : (safePlacesOnRoute ?? this.safePlacesOnRoute),
      );
}

/// Loads nearby havens (network first, offline cache as fallback) and scores
/// walking routes by how many havens they pass.
class MapController extends Notifier<MapState> {
  @override
  MapState build() {
    Future.microtask(load);
    return const MapState();
  }

  Future<void> load() async {
    state = state.copyWith(phase: MapPhase.loading);
    final location = ref.read(locationServiceProvider);

    final granted = await _try(() => location.ensurePermission(), false);
    GeoPoint? me;
    if (granted) {
      final fix = await _try<Result<LocationFix>>(
        () => location.currentFix(),
        const Err('Location unavailable'),
      );
      me = fix.valueOrNull?.point;
    }

    final online = await _try(() => ref.read(connectivityServiceProvider).isOnline(), true);
    List<SafeHaven>? fresh;
    if (online) {
      final res = await _try<Result<List<SafeHaven>>>(
        () => ref.read(havenServiceProvider).nearby(me ?? fallbackCenter),
        const Err('Network error'),
      );
      fresh = res.valueOrNull;
    }

    final cache = ref.read(havenCacheRepositoryProvider);
    List<SafeHaven> havens;
    var fromCache = false;
    if (fresh != null) {
      havens = fresh;
      if (fresh.isNotEmpty) unawaited(_try(() => cache.replaceAll(fresh!), null));
    } else {
      havens = await _try(() => cache.cached(), const <SafeHaven>[]);
      fromCache = true;
    }
    if (!ref.mounted) return;
    if (me != null) havens = Proximity.sortByDistance(me, havens);

    state = MapState(
      phase: granted ? MapPhase.ready : MapPhase.permissionDenied,
      me: me,
      havens: havens,
      fromCache: fromCache,
      filters: state.filters,
    );
  }

  void toggleFilter(HavenCategory c) {
    final next = {...state.filters};
    if (!next.remove(c)) next.add(c);
    state = state.copyWith(filters: next);
  }

  void clearRoute() => state = state.copyWith(clearRoute: true);

  /// Fetches walking alternatives to [target] and picks the safest.
  Future<void> walkTo(SafeHaven target) async {
    final me = state.me;
    if (me == null) {
      state = state.copyWith(routeTarget: target, routeError: 'Turn on location to plan a walking route.');
      return;
    }
    state = state.copyWith(clearRoute: true);
    state = state.copyWith(routeTarget: target, routeLoading: true);
    final res = await _try<Result<List<WalkRoute>>>(
      () => ref.read(routingServiceProvider).walkingRoutes(me, target.point),
      const Err('Routing failed'),
    );
    if (!ref.mounted) return;
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
        state = state.copyWith(routeLoading: false, routeError: 'No walking route found.');
      case Err():
        state = state.copyWith(routeLoading: false, routeError: 'Could not load a route. Check your connection.');
    }
  }

  static int countOnRoute(WalkRoute r, List<SafeHaven> havens) => havens
      .where((h) => r.points.any((p) => Proximity.within(h.point, p, routeCoverM)))
      .length;

  Future<T> _try<T>(Future<T> Function() f, T fallback) async {
    try {
      return await f();
    } catch (_) {
      return fallback;
    }
  }
}

final mapControllerProvider = NotifierProvider<MapController, MapState>(MapController.new);
