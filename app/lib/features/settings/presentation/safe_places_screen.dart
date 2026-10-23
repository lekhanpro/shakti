import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';

final savedPlacesProvider = StreamProvider<List<SafePlace>>(
  (ref) => ref.watch(safePlaceRepositoryProvider).watchAll(),
);

class SafePlacesScreen extends ConsumerStatefulWidget {
  const SafePlacesScreen({super.key});
  @override
  ConsumerState<SafePlacesScreen> createState() => _SafePlacesState();
}

class _SafePlacesState extends ConsumerState<SafePlacesScreen> {
  bool _busy = false;
  Future<void> _add() async {
    final name = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: const Text('Save your current location'),
        content: TextField(
          controller: name,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Place name, e.g. Home'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                Navigator.pop(ctx, name.text.trim());
              }
            },
            child: const Text('Use current location'),
          ),
        ],
      ),
    );
    name.dispose();
    if (label == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final location = ref.read(locationServiceProvider);
      if (!await location.ensurePermission()) {
        throw StateError('Location permission denied');
      }
      final fix = (await location.currentFix()).valueOrNull;
      if (fix == null ||
          ref.read(clockProvider).now().difference(fix.at).abs() >
              const Duration(minutes: 2)) {
        throw StateError('A recent location fix is required');
      }
      await ref
          .read(safePlaceRepositoryProvider)
          .upsert(
            SafePlace(id: const Uuid().v4(), name: label, point: fix.point),
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this place. Enable location and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(SafePlace place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${place.name}?'),
        content: const Text(
          'This place will no longer be available for arrival checks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(safePlaceRepositoryProvider).delete(place.id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not remove the place.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Safe places')),
    body: ShaktiBackdrop(
      child: ref
          .watch(savedPlacesProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => EmptyState(
              icon: Icons.location_off_outlined,
              title: 'Could not load places',
              message: 'Try loading your saved arrival points again.',
              action: OutlinedButton.icon(
                onPressed: () => ref.invalidate(savedPlacesProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
            data: (places) => ListView(
              padding: ShaktiSpace.screen.copyWith(bottom: ShaktiSpace.xl),
              children: [
                const ShaktiPageHeader(
                  title: 'Familiar destinations.',
                  subtitle: 'Arrival points for Walk with me.',
                ),
                GlassSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        color: ShaktiColors.lilac,
                        size: 28,
                      ),
                      const SizedBox(height: ShaktiSpace.sm),
                      Text(
                        'A check-in when you arrive',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: ShaktiSpace.xs),
                      const Text(
                        'During Walk With Me, entering a 150 m radius prompts a PIN-protected arrival check. A saved place is not a guarantee of safety.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ShaktiSpace.md),
                FilledButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(_busy ? 'Locating...' : 'Add current place'),
                ),
                const SectionHeader('Saved places'),
                if (places.isEmpty)
                  ShaktiCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bookmark_border_rounded,
                          color: ShaktiColors.textLo,
                        ),
                        const SizedBox(height: ShaktiSpace.sm),
                        Text(
                          'No places saved.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: ShaktiSpace.xs),
                        const Text(
                          'Add Home, College or another destination while you are there. Shakti saves your current location.',
                        ),
                      ],
                    ),
                  ),
                for (final p in places) ...[
                  ShaktiCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: ShaktiColors.lilac.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              ShaktiRadius.md,
                            ),
                          ),
                          child: const Icon(
                            Icons.place_outlined,
                            color: ShaktiColors.lilac,
                          ),
                        ),
                        const SizedBox(width: ShaktiSpace.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: ShaktiSpace.xxs),
                              Text(
                                '${p.radiusM.toInt()} m arrival radius',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${p.name}',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(p),
                          constraints: const BoxConstraints(
                            minWidth: ShaktiSize.minTap,
                            minHeight: ShaktiSize.minTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: ShaktiSpace.sm),
                ],
              ],
            ),
          ),
    ),
  );
}
