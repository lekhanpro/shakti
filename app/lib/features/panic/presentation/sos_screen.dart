import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/countdown_ring.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/swipe_to_cancel.dart';
import '../../../domain/engines/pin_hasher.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import '../../home/application/startup.dart';
import '../application/panic_controller.dart';
import '../application/panic_view_state.dart';

/// One screen for the whole visible emergency: countdown, active, resolved.
/// Covert incidents never reach it (the gate stays on the decoy UI).
class SosScreen extends ConsumerWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(panicGateSyncProvider);
    final s = ref.watch(panicControllerProvider);
    // Back never leaves an emergency by accident.
    return PopScope(
      canPop: s.phase == PanicPhase.idle,
      child: AnimatedSwitcher(
        duration: ShaktiMotion.reduced(context) ? Duration.zero : ShaktiMotion.base,
        child: switch (s.phase) {
          PanicPhase.countdown => CountdownView(state: s, key: const ValueKey('countdown')),
          PanicPhase.active => ActiveView(state: s, key: const ValueKey('active')),
          PanicPhase.resolved => ResolvedView(state: s, key: const ValueKey('resolved')),
          PanicPhase.idle => const Scaffold(key: ValueKey('idle'), body: SizedBox.shrink()),
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Countdown
// -----------------------------------------------------------------------------

class CountdownView extends ConsumerWidget {
  const CountdownView({required this.state, super.key});

  final PanicViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: ShaktiColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.2,
            colors: [ShaktiColors.sosDeep, ShaktiColors.bg],
            stops: [0, 0.9],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, ShaktiSpace.xl, ShaktiSpace.lg, ShaktiSpace.lg),
            child: Column(
              children: [
                Semantics(
                  header: true,
                  child: Text('Sending SOS in', style: t.headlineMedium?.copyWith(color: ShaktiColors.textHi)),
                ),
                const SizedBox(height: ShaktiSpace.xs),
                Text(
                  'Started by ${state.source?.label ?? 'SOS button'}',
                  style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
                ),
                const Spacer(),
                LayoutBuilder(
                  builder: (context, c) => CountdownRing(
                    secondsLeft: state.secondsLeft,
                    total: state.totalSeconds,
                    size: (c.maxWidth * 0.72).clamp(180.0, 300.0),
                  ),
                ),
                const Spacer(),
                Text(
                  'Shakti will attempt SMS to your enabled contacts. Location is included when available.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: ShaktiColors.textMid),
                ),
                const SizedBox(height: ShaktiSpace.lg),
                SwipeToCancel(onCancel: () => ref.read(panicControllerProvider.notifier).abort()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Active
// -----------------------------------------------------------------------------

class ActiveView extends ConsumerStatefulWidget {
  const ActiveView({required this.state, super.key});

  final PanicViewState state;

  @override
  ConsumerState<ActiveView> createState() => _ActiveViewState();
}

class _ActiveViewState extends ConsumerState<ActiveView> {
  Timer? _tick;
  bool? _sirenOverride;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _sirenOn {
    final o = _sirenOverride;
    if (o != null) return o;
    return widget.state.report?.status(DispatchChannel.siren) == ChannelStatus.ok;
  }

  Future<void> _toggleSiren() async {
    final siren = ref.read(sirenServiceProvider);
    final next = !_sirenOn;
    setState(() => _sirenOverride = next);
    try {
      next ? await siren.start() : await siren.stop();
    } catch (_) {
      if (mounted) setState(() => _sirenOverride = !next);
    }
  }

  Future<void> _call112() async {
    try {
      await launchUrl(Uri(scheme: 'tel', path: '112'));
    } catch (_) {}
  }

  Future<void> _imSafe({bool falseAlarm = false}) async {
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => VerifyPinSheet(falseAlarm: falseAlarm),
    );
    if (verified == true) {
      await ref.read(panicControllerProvider.notifier).resolve(falseAlarm: falseAlarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = widget.state;
    final now = ref.read(clockProvider).now();
    final elapsed = s.startedAt == null ? Duration.zero : now.difference(s.startedAt!);
    final report = s.report;

    return Scaffold(
      backgroundColor: ShaktiColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, ShaktiSpace.lg, ShaktiSpace.lg, 0),
              sliver: SliverList.list(children: [
                Row(
                  children: [
                    const _LivePulse(),
                    const SizedBox(width: ShaktiSpace.sm),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text('SOS active', style: t.displaySmall?.copyWith(color: ShaktiColors.textHi)),
                      ),
                    ),
                    Semantics(
                      label: 'Elapsed ${_spoken(elapsed)}',
                      excludeSemantics: true,
                      child: Text(
                        _clock(elapsed),
                        style: t.headlineMedium?.copyWith(
                          color: ShaktiColors.sosGlow,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: ShaktiSpace.xs),
                Text(
                  report == null
                      ? 'Starting alerts'
                      : report.smsRecipients > 0
                          ? 'Android accepted SMS for ${report.smsRecipients} ${report.smsRecipients == 1 ? 'contact' : 'contacts'}. Delivery is unconfirmed.'
                          : 'Stay where people can see you. Call 112 if you can.',
                  style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
                ),
                const SizedBox(height: ShaktiSpace.lg),
                ChannelChecklist(report: report),
                const SizedBox(height: ShaktiSpace.lg),
              ]),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, 0, ShaktiSpace.lg, ShaktiSpace.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('call-112'),
                      onPressed: _call112,
                      style: FilledButton.styleFrom(
                        backgroundColor: ShaktiColors.sos,
                        foregroundColor: ShaktiColors.textHi,
                        minimumSize: const Size.fromHeight(72),
                        textStyle: t.headlineSmall,
                      ),
                      icon: const Icon(Icons.call_rounded, size: 28),
                      label: const Text('Call 112'),
                    ),
                    const SizedBox(height: ShaktiSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('siren-toggle'),
                            onPressed: _toggleSiren,
                            icon: Icon(_sirenOn ? Icons.volume_off_rounded : Icons.campaign_rounded),
                            label: Text(_sirenOn ? 'Siren off' : 'Siren on'),
                          ),
                        ),
                        const SizedBox(width: ShaktiSpace.sm),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('im-safe'),
                            onPressed: () => _imSafe(),
                            style: FilledButton.styleFrom(
                              backgroundColor: ShaktiColors.safeDeep,
                              foregroundColor: ShaktiColors.textHi,
                            ),
                            icon: const Icon(Icons.verified_user_rounded),
                            label: const Text("I'm safe"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ShaktiSpace.xs),
                    TextButton(
                      key: const ValueKey('false-alarm'),
                      onPressed: () => _imSafe(falseAlarm: true),
                      style: TextButton.styleFrom(foregroundColor: ShaktiColors.textLo),
                      child: const Text('It was a false alarm'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _clock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

String _spoken(Duration d) {
  final m = d.inMinutes, s = d.inSeconds.remainder(60);
  return m == 0 ? '$s seconds' : '$m minutes $s seconds';
}

class _LivePulse extends StatefulWidget {
  const _LivePulse();

  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: ShaktiMotion.breathe);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ShaktiMotion.reduced(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: ShaktiColors.sos,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: ShaktiColors.sos.withValues(alpha: 0.6), blurRadius: 10)],
          ),
        ),
      ),
    );
  }
}

/// Live per-channel status. Every row pairs an icon and a word with the
/// colour, so status never depends on colour alone.
class ChannelChecklist extends StatelessWidget {
  const ChannelChecklist({required this.report, super.key});

  final DispatchReport? report;

  static const _order = [
    DispatchChannel.localSave,
    DispatchChannel.location,
    DispatchChannel.sms,
    DispatchChannel.cloud,
    DispatchChannel.audio,
    DispatchChannel.siren,
    DispatchChannel.tracking,
  ];

  @override
  Widget build(BuildContext context) {
    final r = report;
    return Container(
      decoration: BoxDecoration(
        color: ShaktiColors.surface,
        borderRadius: BorderRadius.circular(ShaktiRadius.card),
        border: Border.all(color: ShaktiColors.outline.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
      child: Column(
        children: [
          for (final c in _order)
            _ChannelRow(
              channel: c,
              status: r?.status(c) ?? ChannelStatus.pending,
              note: r?.notes[c],
            ),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({required this.channel, required this.status, this.note});

  final DispatchChannel channel;
  final ChannelStatus status;
  final String? note;

  static (IconData, Color, String) _look(ChannelStatus s) => switch (s) {
        ChannelStatus.pending => (Icons.schedule_rounded, ShaktiColors.textLo, 'Waiting'),
        ChannelStatus.running => (Icons.sync_rounded, ShaktiColors.info, 'Working'),
        ChannelStatus.ok => (Icons.check_circle_rounded, ShaktiColors.safe, 'Done'),
        ChannelStatus.failed => (Icons.error_rounded, ShaktiColors.sosGlow, 'Failed'),
        ChannelStatus.skipped => (Icons.remove_circle_outline_rounded, ShaktiColors.textLo, 'Off'),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (icon, color, word) = _look(status);
    return Semantics(
      liveRegion: status == ChannelStatus.failed || status == ChannelStatus.ok,
      label: '${channel.label}: $word${note == null ? '' : '. $note'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.md, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, color: color, size: 22)),
            const SizedBox(width: ShaktiSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(channel.label, style: t.titleMedium),
                  if (note != null) Text(note!, style: t.bodySmall?.copyWith(color: ShaktiColors.textMid)),
                ],
              ),
            ),
            const SizedBox(width: ShaktiSpace.xs),
            Text(word, style: t.labelMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Verifies the primary PIN (or biometrics when enabled) before ending an SOS.
/// Pops `true` on success.
class VerifyPinSheet extends ConsumerStatefulWidget {
  const VerifyPinSheet({this.falseAlarm = false, super.key});

  final bool falseAlarm;

  @override
  ConsumerState<VerifyPinSheet> createState() => _VerifyPinSheetState();
}

class _VerifyPinSheetState extends ConsumerState<VerifyPinSheet> {
  final _pad = GlobalKey<PinPadState>();
  String? _error;
  bool _busy = false;

  Future<void> _check(String pin) async {
    setState(() => _busy = true);
    final hash = await ref.read(secureStoreProvider).read(PinKeys.primary);
    // No PIN was ever set: the user cannot be locked into an SOS.
    final ok = hash == null || await PinHasher.verify(pin, hash);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _pad.currentState?.clear();
      setState(() {
        _busy = false;
        _error = 'Wrong PIN. The SOS is still active';
      });
    }
  }

  Future<void> _biometric() async {
    final bio = ref.read(biometricServiceProvider);
    try {
      if (await bio.available && await bio.authenticate('Confirm you are safe')) {
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bio = ref.watch(liveSettingsProvider).value?.biometricUnlock ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, 0, ShaktiSpace.lg, ShaktiSpace.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: Text(widget.falseAlarm ? 'End as a false alarm' : "Confirm you're safe", style: t.headlineSmall),
          ),
          const SizedBox(height: ShaktiSpace.xs),
          Text(
            'Enter your PIN. Your contacts will get an "I am safe" message.',
            textAlign: TextAlign.center,
            style: t.bodyMedium,
          ),
          const SizedBox(height: ShaktiSpace.sm),
          PinPad(key: _pad, onSubmit: _check, enabled: !_busy, errorText: _error, submitLabel: 'Confirm'),
          if (bio)
            TextButton.icon(
              onPressed: _biometric,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Use fingerprint'),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Resolved
// -----------------------------------------------------------------------------

class ResolvedView extends ConsumerWidget {
  const ResolvedView({required this.state, super.key});

  final PanicViewState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final report = state.report;
    final inc = report?.incident;
    final end = inc?.resolvedAt ?? ref.read(clockProvider).now();
    final start = state.startedAt ?? inc?.createdAt ?? end;
    final duration = end.difference(start);
    final reached = [
      for (final c in [DispatchChannel.sms, DispatchChannel.cloud, DispatchChannel.tracking])
        if (report?.status(c) == ChannelStatus.ok) c,
    ];
    final falseAlarm = inc?.status == IncidentStatus.falseAlarm;

    return Scaffold(
      backgroundColor: ShaktiColors.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.6),
            radius: 1.1,
            colors: [ShaktiColors.safeDeep.withValues(alpha: 0.45), ShaktiColors.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ShaktiSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Icon(Icons.verified_user_rounded, color: ShaktiColors.safe, size: 56),
                const SizedBox(height: ShaktiSpace.md),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(falseAlarm ? 'Marked as a false alarm' : "You're marked safe", style: t.displaySmall),
                ),
                const SizedBox(height: ShaktiSpace.xs),
                Text(
                  inc?.covert ?? false
                      ? 'The alert has ended.'
                      : 'Your contacts are getting an "I am safe" message now.',
                  style: t.bodyLarge?.copyWith(color: ShaktiColors.textMid),
                ),
                const SizedBox(height: ShaktiSpace.xl),
                _SummaryLine(icon: Icons.timer_outlined, text: 'SOS lasted ${_spoken(duration)}'),
                if (reached.isEmpty)
                  const _SummaryLine(icon: Icons.info_outline_rounded, text: 'No alert reached anyone before it ended')
                else
                  for (final c in reached)
                    _SummaryLine(
                      icon: Icons.check_circle_rounded,
                      text: c == DispatchChannel.sms && (report?.smsRecipients ?? 0) > 0
                          ? 'SMS reached ${report!.smsRecipients} ${report.smsRecipients == 1 ? 'contact' : 'contacts'}'
                          : '${c.label} worked',
                    ),
                const Spacer(flex: 2),
                FilledButton(
                  key: const ValueKey('resolved-done'),
                  onPressed: () => ref.read(panicControllerProvider.notifier).acknowledge(),
                  style: FilledButton.styleFrom(
                    backgroundColor: ShaktiColors.safeDeep,
                    foregroundColor: ShaktiColors.textHi,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
        child: Row(
          children: [
            Icon(icon, color: ShaktiColors.safe, size: 22),
            const SizedBox(width: ShaktiSpace.sm),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      );
}
