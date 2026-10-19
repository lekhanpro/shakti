import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/engines/proximity.dart';
import '../../../domain/entities/entities.dart';
import '../application/map_controller.dart' hide MapController;
import 'haven_style.dart';

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lng);

/// CartoDB dark basemap: quieter than stock OSM at night, and markers pop.
const _tileUrl = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

class SafetyMapScreen extends ConsumerStatefulWidget {
  const SafetyMapScreen({this.showTiles = true, super.key});

  /// Tests disable network tiles.
  final bool showTiles;

  @override
  ConsumerState<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends ConsumerState<SafetyMapScreen> {
  final _map = MapController();
  bool _mapReady = false;

  void _recenter() {
    final s = ref.read(mapControllerProvider);
    if (_mapReady) _map.move(_ll(s.center), 15);
  }

  void _focus(SafeHaven h) {
    if (_mapReady) _map.move(_ll(h.point), 16);
  }

  Future<void> _walk(SafeHaven h) async {
    await ref.read(mapControllerProvider.notifier).walkTo(h);
    final s = ref.read(mapControllerProvider);
    final best = s.bestRoute;
    if (best != null && best.points.length > 1 && _mapReady) {
      _map.fitCamera(CameraFit.coordinates(
        coordinates: [for (final p in best.points) _ll(p)],
        padding: const EdgeInsets.fromLTRB(48, 160, 48, 320),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mapControllerProvider);
    final ctrl = ref.read(mapControllerProvider.notifier);
    ref.listen(mapControllerProvider.select((v) => v.me), (prev, next) {
      if (prev == null && next != null && _mapReady) _map.move(_ll(next), 15);
    });

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildMap(s)),
          // Top: title + filters over a scrim so they read against any tile.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(state: s, onToggle: ctrl.toggleFilter, onRetry: ctrl.load),
          ),
          Positioned.fill(
            child: _HavenSheet(
              state: s,
              onFocus: _focus,
              onWalk: _walk,
              onRecenter: _recenter,
              onClearRoute: ctrl.clearRoute,
              onRetry: ctrl.load,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(MapState s) {
    final routes = s.routes;
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _ll(s.center),
        initialZoom: 14,
        backgroundColor: ShaktiColors.bg,
        onMapReady: () => _mapReady = true,
      ),
      children: [
        if (widget.showTiles)
          TileLayer(
            urlTemplate: _tileUrl,
            subdomains: const ['a', 'b', 'c', 'd'],
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: 'in.shakti.shakti',
          ),
        if (routes.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (var i = 0; i < routes.length; i++)
                if (i != s.bestIndex)
                  Polyline(
                    points: [for (final p in routes[i].points) _ll(p)],
                    strokeWidth: 4,
                    color: ShaktiColors.textLo.withValues(alpha: 0.45),
                  ),
              if (s.bestRoute != null)
                Polyline(
                  points: [for (final p in s.bestRoute!.points) _ll(p)],
                  strokeWidth: 7,
                  color: ShaktiColors.safe,
                  borderStrokeWidth: 2,
                  borderColor: ShaktiColors.bg,
                ),
            ],
          ),
        MarkerLayer(
          markers: [
            for (final h in s.visible)
              Marker(
                point: _ll(h.point),
                width: 48,
                height: 48,
                child: _HavenPin(haven: h, selected: s.routeTarget == h, onTap: () => _focus(h)),
              ),
            if (s.me != null)
              Marker(point: _ll(s.me!), width: 48, height: 48, child: const _MePin()),
          ],
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            ),
            TextSourceAttribution(
              'CARTO',
              onTap: () => launchUrl(Uri.parse('https://carto.com/attributions')),
            ),
          ],
        ),
        // Always-visible credit line; the rich widget above is collapsible.
        const Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.only(right: ShaktiSpace.xs, bottom: 112),
            child: _Credit(),
          ),
        ),
      ],
    );
  }
}

class _Credit extends StatelessWidget {
  const _Credit();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: ShaktiColors.bg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(ShaktiRadius.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text('© OpenStreetMap, © CARTO', style: Theme.of(context).textTheme.labelSmall),
        ),
      );
}

class _MePin extends StatelessWidget {
  const _MePin();

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Your location',
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: ShaktiColors.info,
              shape: BoxShape.circle,
              border: Border.all(color: ShaktiColors.textHi, width: 3),
              boxShadow: [BoxShadow(color: ShaktiColors.info.withValues(alpha: 0.5), blurRadius: 16, spreadRadius: 6)],
            ),
          ),
        ),
      );
}

class _HavenPin extends StatelessWidget {
  const _HavenPin({required this.haven, required this.selected, required this.onTap});

  final SafeHaven haven;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = haven.category.color;
    return Semantics(
      button: true,
      label: '${haven.category.label}: ${haven.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: ShaktiMotion.fast,
            width: selected ? 40 : 32,
            height: selected ? 40 : 32,
            decoration: BoxDecoration(
              color: ShaktiColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c, width: selected ? 3 : 2),
            ),
            child: Icon(haven.category.icon, size: selected ? 22 : 18, color: c),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state, required this.onToggle, required this.onRetry});

  final MapState state;
  final ValueChanged<HavenCategory> onToggle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ShaktiColors.bg, ShaktiColors.bg.withValues(alpha: 0.85), ShaktiColors.bg.withValues(alpha: 0)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, ShaktiSpace.sm, 20, ShaktiSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(header: true, child: Text('Safe places near you', style: t.headlineSmall)),
              if (state.fromCache && state.phase != MapPhase.loading) ...[
                const SizedBox(height: ShaktiSpace.xs),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: ShaktiSpace.xs,
                  children: [
                    const StatusPill(
                      label: 'Offline. Showing saved places',
                      icon: Icons.cloud_off_rounded,
                      color: ShaktiColors.warn,
                    ),
                    TextButton(onPressed: onRetry, child: const Text('Refresh')),
                  ],
                ),
              ],
              const SizedBox(height: ShaktiSpace.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final c in HavenCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: ShaktiSpace.xs),
                        child: FilterChip(
                          selected: state.filters.contains(c),
                          onSelected: (_) => onToggle(c),
                          showCheckmark: false,
                          avatar: Icon(c.icon, size: 18, color: c.color),
                          label: Text(c.filterLabel),
                          selectedColor: c.color.withValues(alpha: 0.18),
                          side: BorderSide(
                            color: state.filters.contains(c) ? c.color.withValues(alpha: 0.7) : ShaktiColors.outline,
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HavenSheet extends StatelessWidget {
  const _HavenSheet({
    required this.state,
    required this.onFocus,
    required this.onWalk,
    required this.onRecenter,
    required this.onClearRoute,
    required this.onRetry,
  });

  final MapState state;
  final ValueChanged<SafeHaven> onFocus;
  final ValueChanged<SafeHaven> onWalk;
  final VoidCallback onRecenter;
  final VoidCallback onClearRoute;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.14,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.14, 0.34, 0.85],
      builder: (context, scroll) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: ShaktiColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(ShaktiRadius.lg)),
                border: Border(top: BorderSide(color: ShaktiColors.outline)),
              ),
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  const SliverToBoxAdapter(child: _Grabber()),
                  if (state.routeTarget != null)
                    SliverToBoxAdapter(child: _RouteCard(state: state, onClear: onClearRoute)),
                  ..._body(context),
                  const SliverToBoxAdapter(child: SizedBox(height: ShaktiSpace.xl)),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: -64,
              child: Semantics(
                button: true,
                label: 'Recenter map on my location',
                child: FloatingActionButton.small(
                  heroTag: 'map-recenter',
                  onPressed: onRecenter,
                  backgroundColor: ShaktiColors.surfaceHigh,
                  foregroundColor: ShaktiColors.textHi,
                  tooltip: 'Recenter',
                  child: const Icon(Icons.my_location_rounded),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _body(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (state.phase == MapPhase.loading) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(ShaktiSpace.xl),
            child: Center(
              child: Semantics(label: 'Finding safe places', child: const CircularProgressIndicator()),
            ),
          ),
        ),
      ];
    }
    final visible = state.visible;
    return [
      if (state.phase == MapPhase.permissionDenied)
        SliverToBoxAdapter(
          child: Padding(
            padding: ShaktiSpace.screen,
            child: ShaktiCard(
              borderColor: ShaktiColors.warn.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.location_off_rounded, color: ShaktiColors.warn),
                    const SizedBox(width: ShaktiSpace.sm),
                    Expanded(child: Text('Location is off', style: t.titleMedium)),
                  ]),
                  const SizedBox(height: ShaktiSpace.xs),
                  Text(
                    'Allow location so Shakti can sort places by distance and plan a walking route.',
                    style: t.bodyMedium,
                  ),
                  const SizedBox(height: ShaktiSpace.sm),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.my_location_rounded),
                    label: const Text('Allow location'),
                  ),
                ],
              ),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, ShaktiSpace.sm, 20, ShaktiSpace.xs),
        sliver: SliverToBoxAdapter(
          child: Semantics(
            header: true,
            child: Text(
              visible.isEmpty ? 'Nearest safe places' : '${visible.length} nearest safe places',
              style: t.titleMedium,
            ),
          ),
        ),
      ),
      if (visible.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.travel_explore_rounded,
            title: state.havens.isEmpty ? 'No safe places found yet' : 'Nothing matches these filters',
            message: state.havens.isEmpty
                ? 'Connect to the internet once and Shakti will save nearby police, hospitals and pharmacies for offline use.'
                : 'Turn a filter back on to see more places.',
            action: state.havens.isEmpty ? OutlinedButton(onPressed: onRetry, child: const Text('Try again')) : null,
          ),
        )
      else
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: ShaktiSpace.xs),
          itemBuilder: (context, i) => Padding(
            padding: ShaktiSpace.screen,
            child: _HavenTile(
              haven: visible[i],
              distanceM: state.distanceTo(visible[i]),
              onFocus: () => onFocus(visible[i]),
              onWalk: () => onWalk(visible[i]),
            ),
          ),
        ),
    ];
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: ShaktiSpace.sm),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ShaktiColors.outline,
            borderRadius: BorderRadius.circular(ShaktiRadius.pill),
          ),
        ),
      );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.state, required this.onClear});

  final MapState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final target = state.routeTarget!;
    final best = state.bestRoute;
    Widget body;
    if (state.routeLoading) {
      body = Row(children: [
        const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: ShaktiSpace.sm),
        Expanded(child: Text('Comparing walking routes…', style: t.bodyMedium)),
      ]);
    } else if (state.routeError != null) {
      body = Text(state.routeError!, style: t.bodyMedium?.copyWith(color: ShaktiColors.warn));
    } else if (best != null) {
      final mins = (best.durationS / 60).ceil();
      final n = state.safePlacesOnRoute;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Safest route: passes $n safe ${n == 1 ? 'place' : 'places'}',
            style: t.titleMedium?.copyWith(color: ShaktiColors.safe),
          ),
          const SizedBox(height: ShaktiSpace.xxs),
          Text(
            '${Proximity.formatDistance(best.distanceM)}, about $mins min on foot'
            '${state.routes.length > 1 ? '. ${state.routes.length - 1} other route${state.routes.length > 2 ? 's' : ''} shown faint.' : '.'}',
            style: t.bodyMedium,
          ),
        ],
      );
    } else {
      body = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, ShaktiSpace.sm),
      child: ShaktiCard(
        borderColor: ShaktiColors.safe.withValues(alpha: 0.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.directions_walk_rounded, color: ShaktiColors.safe),
            ),
            const SizedBox(width: ShaktiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('To ${target.name}', style: t.labelMedium),
                  const SizedBox(height: ShaktiSpace.xxs),
                  body,
                ],
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: 'Clear route',
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _HavenTile extends StatelessWidget {
  const _HavenTile({required this.haven, required this.distanceM, required this.onFocus, required this.onWalk});

  final SafeHaven haven;
  final double? distanceM;
  final VoidCallback onFocus;
  final VoidCallback onWalk;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = haven.category.color;
    final meta = [
      if (distanceM != null) Proximity.formatDistance(distanceM!),
      haven.category.label,
      if (haven.open24h) 'Open 24 hours',
    ].join(', ');
    return ShaktiCard(
      onTap: onFocus,
      semanticLabel: 'Show ${haven.name} on the map',
      padding: const EdgeInsets.fromLTRB(ShaktiSpace.md, ShaktiSpace.sm, ShaktiSpace.sm, ShaktiSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(haven.category.icon, color: c, size: 22),
              ),
              const SizedBox(width: ShaktiSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(haven.name, style: t.titleSmall),
                    const SizedBox(height: 2),
                    Text(meta, style: t.bodySmall),
                    if (haven.address != null && haven.address!.isNotEmpty)
                      Text(haven.address!, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ShaktiSpace.xs),
          Wrap(
            spacing: ShaktiSpace.xs,
            runSpacing: ShaktiSpace.xxs,
            children: [
              if (haven.phone != null && haven.phone!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: haven.phone!.replaceAll(' ', ''))),
                  icon: const Icon(Icons.call_rounded, size: 20),
                  label: const Text('Call'),
                ),
              TextButton.icon(
                onPressed: onWalk,
                icon: const Icon(Icons.directions_walk_rounded, size: 20),
                label: const Text('Walk here'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
