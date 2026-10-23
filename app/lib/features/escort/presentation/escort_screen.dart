import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/engines/escort_timer.dart';
import '../../../domain/entities/entities.dart';
import '../application/escort_controller.dart';
import 'pin_check_sheet.dart';

final _safePlacesProvider = StreamProvider.autoDispose<List<SafePlace>>(
  (ref) => ref.watch(safePlaceRepositoryProvider).watchAll(),
);

String formatEscort(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class EscortScreen extends ConsumerWidget {
  const EscortScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(escortControllerProvider);
    ref.listen(escortControllerProvider.select((v) => v.warned), (prev, next) {
      if (next && prev == false && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2 minutes left. Check in or add time, or your contacts get an SOS.')),
        );
      }
    });
    return Scaffold(
      body: ShaktiBackdrop(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: ShaktiMotion.reduced(context) ? Duration.zero : ShaktiMotion.navigation,
            child: switch (s.status) {
              EscortStatus.running => const _RunningView(key: ValueKey('running')),
              EscortStatus.checkedIn => _DoneView(key: const ValueKey('done'), state: s),
              EscortStatus.expired => const _ExpiredView(key: ValueKey('expired')),
              EscortStatus.idle => const _SetupView(key: ValueKey('setup')),
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Setup
// ---------------------------------------------------------------------------

class _SetupView extends ConsumerStatefulWidget {
  const _SetupView({super.key});

  @override
  ConsumerState<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<_SetupView> {
  static const _presets = [10, 15, 20, 30, 45];
  int _minutes = 15;
  SafePlace? _dest;

  void _step(int by) => setState(() => _minutes = (_minutes + by).clamp(1, 180));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final places = ref.watch(_safePlacesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, ShaktiSpace.xs, ShaktiSpace.lg, ShaktiSpace.dockClearance),
      children: [
        const ShaktiPageHeader(title: 'Walk with me', subtitle: 'A little company. All the way home.'),
        GlassSurface(
          color: ShaktiColors.ambient,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.directions_walk_rounded, color: ShaktiColors.lilac),
              const SizedBox(width: ShaktiSpace.sm),
              Expanded(
                child: Text(
                  'Choose your time. If you do not check in with your PIN before it ends, Shakti sends an SOS for you.',
                  style: t.bodyMedium?.copyWith(color: ShaktiColors.textMid),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader('How long'),
        Wrap(
          spacing: ShaktiSpace.xs,
          runSpacing: ShaktiSpace.xs,
          children: [
            for (final m in _presets)
              ChoiceChip(
                label: Text('$m min'),
                selected: _minutes == m,
                onSelected: (_) => setState(() => _minutes = m),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
          ],
        ),
        const SizedBox(height: ShaktiSpace.md),
        ShaktiCard(
          padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.xs, vertical: ShaktiSpace.xs),
          child: Row(
            children: [
              IconButton(
                onPressed: _minutes > 1 ? () => _step(-1) : null,
                tooltip: 'One minute less',
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  label: '$_minutes minutes',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text('$_minutes', style: t.displaySmall),
                      Text('minutes', style: t.labelMedium),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: _minutes < 180 ? () => _step(1) : null,
                tooltip: 'One minute more',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        const SectionHeader('Where to (optional)'),
        places.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text('Could not load your places.', style: t.bodyMedium),
          data: (list) => list.isEmpty
              ? Text(
                  'Add Home or College in Settings, Places, and Shakti will notice when you arrive.',
                  style: t.bodyMedium,
                )
              : Wrap(
                  spacing: ShaktiSpace.xs,
                  runSpacing: ShaktiSpace.xs,
                  children: [
                    ChoiceChip(
                      label: const Text('Anywhere'),
                      selected: _dest == null,
                      onSelected: (_) => setState(() => _dest = null),
                    ),
                    for (final p in list)
                      ChoiceChip(
                        avatar: const Icon(Icons.home_rounded, size: 18),
                        label: Text(p.name),
                        selected: _dest?.id == p.id,
                        onSelected: (_) => setState(() => _dest = p),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: ShaktiSpace.lg),
        FilledButton.icon(
          onPressed: () =>
              ref.read(escortControllerProvider.notifier).start(Duration(minutes: _minutes), destination: _dest),
          icon: const Icon(Icons.directions_walk_rounded),
          label: Text('Start $_minutes min walk'),
        ),
        const SizedBox(height: ShaktiSpace.sm),
        Text(
          'Keep Shakti open or in the background. Two minutes before the end your phone vibrates.',
          style: t.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Running
// ---------------------------------------------------------------------------

class _RunningView extends ConsumerWidget {
  const _RunningView({super.key});

  Future<void> _checkIn(BuildContext context, WidgetRef ref, {required bool ending}) async {
    final ctrl = ref.read(escortControllerProvider.notifier);
    await showPinCheckSheet(
      context,
      title: ending ? 'End walk' : 'Check in',
      message: ending
          ? 'Enter your PIN to stop the timer. No one is alerted.'
          : 'Enter your PIN to confirm you are safe.',
      submitLabel: ending ? 'End' : 'Check in',
      verify: ctrl.checkIn,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(escortControllerProvider);
    final t = Theme.of(context).textTheme;
    final ctrl = ref.read(escortControllerProvider.notifier);
    final color = s.warned ? ShaktiColors.warn : ShaktiColors.lilac;

    return LayoutBuilder(
      builder: (context, box) {
        final ring = math.min(264.0, box.maxWidth - ShaktiSpace.xxl);
        return ListView(
          padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, ShaktiSpace.xs, ShaktiSpace.lg, ShaktiSpace.dockClearance),
          children: [
            const ShaktiPageHeader(title: 'Walk with me', subtitle: 'Your walk, at your pace.'),
            if (s.arrivedAt != null && !s.arrivalHandled) ...[
              _ArrivalCard(place: s.arrivedAt!),
              const SizedBox(height: ShaktiSpace.md),
            ],
            Center(
              child: Semantics(
                label: 'Time left ${s.remaining.inMinutes} minutes ${s.remaining.inSeconds % 60} seconds',
                excludeSemantics: true,
                child: SizedBox.square(
                  dimension: ring,
                  child: CustomPaint(
                    painter: _RingPainter(progress: 1 - s.progress, color: color),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(ShaktiSpace.xl),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatEscort(s.remaining),
                                style: t.displayLarge?.copyWith(
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                  color: ShaktiColors.textHi,
                                ),
                              ),
                              Text(
                                s.warned ? 'Check in now' : 'until SOS',
                                style: t.labelMedium?.copyWith(color: color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ShaktiSpace.md),
            GlassSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(s.destination != null ? Icons.place_rounded : Icons.directions_walk_rounded, color: color),
                  const SizedBox(width: ShaktiSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.destination != null ? 'Walking to ${s.destination!.name}' : 'Walk in progress',
                          style: t.titleMedium,
                        ),
                        const SizedBox(height: ShaktiSpace.xxs),
                        Text('Check in before the timer ends to prevent an SOS.', style: t.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ShaktiSpace.xl),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: ShaktiColors.safeDeep),
              onPressed: () => _checkIn(context, ref, ending: false),
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text("Check in, I'm safe"),
            ),
            const SizedBox(height: ShaktiSpace.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ctrl.extend(),
                    icon: const Icon(Icons.more_time_rounded),
                    label: const Text('+5 min'),
                  ),
                ),
                const SizedBox(width: ShaktiSpace.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _checkIn(context, ref, ending: true),
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('End'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ArrivalCard extends ConsumerWidget {
  const _ArrivalCard({required this.place});

  final SafePlace place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final ctrl = ref.read(escortControllerProvider.notifier);
    return Semantics(
      liveRegion: true,
      child: ShaktiCard(
        borderColor: ShaktiColors.safe,
        color: ShaktiColors.safe.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.where_to_vote_rounded, color: ShaktiColors.safe),
                const SizedBox(width: ShaktiSpace.sm),
                Expanded(child: Text('Arrived at ${place.name}', style: t.titleLarge)),
              ],
            ),
            const SizedBox(height: ShaktiSpace.xs),
            Text('End the walk and text your contacts "I reached ${place.name} safely"?', style: t.bodyMedium),
            const SizedBox(height: ShaktiSpace.sm),
            Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              children: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ShaktiColors.safeDeep),
                  onPressed: () => showPinCheckSheet(
                    context,
                    title: 'Confirm safe arrival',
                    message: 'Enter your PIN to end the walk and notify contacts.',
                    submitLabel: 'Check in',
                    verify: (pin) => ctrl.answerArrival(checkIn: true, pin: pin),
                  ),
                  child: const Text('Check in and tell them'),
                ),
                TextButton(onPressed: () => ctrl.answerArrival(checkIn: false), child: const Text('Not yet')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  /// Fraction of time remaining, 1 → 0.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 8.0;
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ShaktiColors.surfaceHigh,
    );
    canvas.drawArc(
      r,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// Terminal states
// ---------------------------------------------------------------------------

class _DoneView extends ConsumerWidget {
  const _DoneView({required this.state, super.key});

  final EscortState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = state.arrivedAt?.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: ShaktiSpace.dockClearance),
      child: EmptyState(
        icon: Icons.verified_user_rounded,
        title: place != null ? 'You reached $place' : 'Walk ended safely',
        message: state.notifiedContacts > 0
            ? 'Told ${state.notifiedContacts} contact${state.notifiedContacts == 1 ? '' : 's'} you are safe.'
            : 'The timer is off. No one was alerted.',
        action: FilledButton(
          onPressed: ref.read(escortControllerProvider.notifier).reset,
          child: const Text('Plan another walk'),
        ),
      ),
    );
  }
}

class _ExpiredView extends ConsumerWidget {
  const _ExpiredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: ShaktiSpace.dockClearance),
    child: EmptyState(
      icon: Icons.emergency_share_rounded,
      title: 'Time ran out',
      message: 'Shakti raised an SOS and is alerting your contacts.',
      action: OutlinedButton(
        onPressed: ref.read(escortControllerProvider.notifier).reset,
        child: const Text('Back to Walk with me'),
      ),
    ),
  );
}
