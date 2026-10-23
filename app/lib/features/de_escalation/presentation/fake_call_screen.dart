import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/glass_surface.dart';
import '../application/ringtone_player.dart';

enum FakeCallPhase { setup, waiting, ringing, inCall }

const fakeCallerPresets = ['Amma', 'Appa', 'Didi', 'Inspector Rao'];
const fakeCallDelays = [(0, 'Now'), (10, '10 s'), (30, '30 s'), (60, '1 min')];

/// Full-screen fake incoming call designed to pass as the stock dialer.
///
/// Flow: setup (caller + delay) -> waiting (countdown) -> ringing -> in call.
/// The status bar is hidden while ringing/in call and restored on exit.
class FakeCallScreen extends ConsumerStatefulWidget {
  const FakeCallScreen({
    this.initialPhase = FakeCallPhase.setup,
    this.callerName,
    super.key,
  });

  /// Tests jump straight to [FakeCallPhase.ringing].
  final FakeCallPhase initialPhase;
  final String? callerName;

  @override
  ConsumerState<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends ConsumerState<FakeCallScreen> {
  late FakeCallPhase _phase = widget.initialPhase;
  late String _caller = widget.callerName ?? 'Amma';
  final _custom = TextEditingController();
  int _delay = 10;
  int _waitLeft = 0;
  int _callSeconds = 0;
  Timer? _timer;
  // Read eagerly in initState: dispose() must not touch ref.
  late final RingtonePlayer _ring;
  bool _immersive = false;

  @override
  void initState() {
    super.initState();
    _ring = ref.read(ringtonePlayerProvider);
    if (widget.callerName == null) {
      ref
          .read(settingsRepositoryProvider)
          .load()
          .then((s) {
            if (!mounted || _phase != FakeCallPhase.setup) return;
            setState(() {
              _caller = s.fakeCallerName.isEmpty ? 'Amma' : s.fakeCallerName;
              _delay = fakeCallDelays.any((d) => d.$1 == s.fakeCallDelaySeconds)
                  ? s.fakeCallDelaySeconds
                  : 10;
              if (!fakeCallerPresets.contains(_caller)) _custom.text = _caller;
            });
          })
          .catchError((_) {});
    }
    if (_phase == FakeCallPhase.ringing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ringNow());
    }
    if (_phase == FakeCallPhase.inCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _answer());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_ring.stop());
    unawaited(_hapticsCancel());
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _custom.dispose();
    super.dispose();
  }

  Future<void> _hapticsCancel() async {
    try {
      await ref.read(hapticsServiceProvider).cancel();
    } catch (_) {}
  }

  void _hideChrome() {
    _immersive = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _schedule() {
    final name =
        _custom.text.trim().isNotEmpty && !fakeCallerPresets.contains(_caller)
        ? _custom.text.trim()
        : _caller;
    _caller = name;
    final delay = _delay;
    // The call starts immediately. Remembering a preference never gates it.
    unawaited(_rememberCall(name, delay));
    if (delay == 0) {
      _ringNow();
      return;
    }
    setState(() {
      _phase = FakeCallPhase.waiting;
      _waitLeft = delay;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_waitLeft <= 1) {
        t.cancel();
        _ringNow();
      } else {
        setState(() => _waitLeft--);
      }
    });
  }

  Future<void> _rememberCall(String name, int delay) async {
    try {
      final repo = ref.read(settingsRepositoryProvider);
      final settings = await repo.load();
      await repo.save(
        settings.copyWith(fakeCallerName: name, fakeCallDelaySeconds: delay),
      );
    } catch (_) {}
  }

  void _ringNow() {
    _timer?.cancel();
    _hideChrome();
    setState(() => _phase = FakeCallPhase.ringing);
    unawaited(_ring.startLoop());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        await ref.read(hapticsServiceProvider).heavy();
      } catch (_) {}
    });
  }

  void _answer() {
    _timer?.cancel();
    unawaited(_ring.stop());
    unawaited(_hapticsCancel());
    _hideChrome();
    setState(() {
      _phase = FakeCallPhase.inCall;
      _callSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  void _end() {
    _timer?.cancel();
    unawaited(_ring.stop());
    unawaited(_hapticsCancel());
    if (_immersive) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _immersive = false;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      setState(() => _phase = FakeCallPhase.setup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      FakeCallPhase.setup => _setup(context),
      FakeCallPhase.waiting => _waiting(context),
      FakeCallPhase.ringing => _Incoming(
        caller: _caller,
        onAnswer: _answer,
        onDecline: _end,
      ),
      FakeCallPhase.inCall => _InCall(
        caller: _caller,
        seconds: _callSeconds,
        onEnd: _end,
      ),
    };
  }

  Widget _setup(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isCustom = !fakeCallerPresets.contains(_caller);
    return Scaffold(
      appBar: AppBar(title: const Text('Fake call')),
      body: ShaktiBackdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ShaktiSpace.lg,
            0,
            ShaktiSpace.lg,
            ShaktiSpace.xl,
          ),
          children: [
            const ShaktiPageHeader(
              title: 'A moment to leave.',
              subtitle: 'Choose a caller and a delay. A simulated call gives you a reason to step away.',
            ),
            GlassSurface(
              padding: const EdgeInsets.all(ShaktiSpace.lg),
              child: Row(
                children: [
                  _Avatar(name: _caller, size: 56),
                  const SizedBox(width: ShaktiSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _caller.trim().isEmpty ? 'Caller name' : _caller,
                          style: t.titleLarge,
                        ),
                        const SizedBox(height: ShaktiSpace.xxs),
                        Text(
                          'Call preview',
                          style: t.bodySmall?.copyWith(
                            color: ShaktiColors.textLo,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: ShaktiSpace.xs),
                  const Icon(
                    Icons.phone_callback_outlined,
                    color: ShaktiColors.lilac,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ShaktiSpace.lg),
            Text('Who is calling', style: t.titleMedium),
            const SizedBox(height: ShaktiSpace.xs),
            Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              children: [
                for (final p in fakeCallerPresets)
                  ChoiceChip(
                    label: Text(p),
                    selected: _caller == p,
                    onSelected: (_) => setState(() => _caller = p),
                  ),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: isCustom,
                  onSelected: (_) => setState(
                    () => _caller = _custom.text.trim().isEmpty
                        ? ' '
                        : _custom.text.trim(),
                  ),
                ),
              ],
            ),
            if (isCustom) ...[
              const SizedBox(height: ShaktiSpace.sm),
              TextField(
                controller: _custom,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Caller name'),
                onChanged: (v) =>
                    setState(() => _caller = v.trim().isEmpty ? ' ' : v.trim()),
              ),
            ],
            const SizedBox(height: ShaktiSpace.lg),
            Text('Ring after', style: t.titleMedium),
            const SizedBox(height: ShaktiSpace.xs),
            Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              children: [
                for (final (s, label) in fakeCallDelays)
                  ChoiceChip(
                    label: Text(label),
                    selected: _delay == s,
                    onSelected: (_) => setState(() => _delay = s),
                  ),
              ],
            ),
            const SizedBox(height: ShaktiSpace.xl),
            FilledButton.icon(
              onPressed: _caller.trim().isEmpty ? null : _schedule,
              icon: const Icon(Icons.phone_callback_rounded),
              label: Text(_delay == 0 ? 'Ring now' : 'Schedule call'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waiting(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Fake call')),
      body: ShaktiBackdrop(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(ShaktiSpace.lg),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_callback_outlined,
                        color: ShaktiColors.lilac,
                        size: 40,
                      ),
                      const SizedBox(height: ShaktiSpace.lg),
                      GlassSurface(
                        padding: const EdgeInsets.all(ShaktiSpace.lg),
                        child: Column(
                          children: [
                            Semantics(
                              liveRegion: true,
                              label: '$_caller calls in $_waitLeft seconds',
                              excludeSemantics: true,
                              child: Text(
                                '$_waitLeft',
                                style: t.displayLarge?.copyWith(
                                  color: ShaktiColors.lilac,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'seconds until $_caller calls',
                              style: t.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ShaktiSpace.lg),
                      Text(
                        'Your simulated call is scheduled. Keep Shakti open until it rings.',
                        style: t.bodyLarge?.copyWith(
                          color: ShaktiColors.textMid,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: ShaktiSpace.lg),
                      OutlinedButton(
                        onPressed: _end,
                        child: const Text('Cancel call'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialer look-alike. Deliberately plain: a stock Android incoming-call screen,
// not Shakti's visual language, so a bystander sees an ordinary call.
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.size = 112});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: ShaktiColors.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.42,
            color: ShaktiColors.textHi,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Incoming extends StatelessWidget {
  const _Incoming({
    required this.caller,
    required this.onAnswer,
    required this.onDecline,
  });

  final String caller;
  final VoidCallback onAnswer;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ShaktiColors.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(ShaktiSpace.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: ShaktiSpace.xl),
                        _Avatar(name: caller),
                        const SizedBox(height: ShaktiSpace.lg),
                        Text(
                          caller,
                          key: const ValueKey('fake-caller-name'),
                          textAlign: TextAlign.center,
                          style: t.displaySmall?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontFamily: ShaktiFonts.body,
                          ),
                        ),
                        const SizedBox(height: ShaktiSpace.xs),
                        Text(
                          'Mobile · Incoming call',
                          textAlign: TextAlign.center,
                          style: t.bodyLarge?.copyWith(
                            color: ShaktiColors.textLo,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: ShaktiSpace.xxl,
                        bottom: ShaktiSpace.lg,
                      ),
                      child: Column(
                        children: [
                          _SlideHint(reduced: ShaktiMotion.reduced(context)),
                          const SizedBox(height: ShaktiSpace.lg),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _RoundAction(
                                  label: 'Decline',
                                  icon: Icons.call_end_rounded,
                                  color: ShaktiColors.sos,
                                  onTap: onDecline,
                                ),
                              ),
                              const SizedBox(width: ShaktiSpace.lg),
                              Expanded(
                                child: _RoundAction(
                                  label: 'Answer',
                                  icon: Icons.call_rounded,
                                  color: ShaktiColors.safe,
                                  onTap: onAnswer,
                                  onSwipeUp: onAnswer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideHint extends StatefulWidget {
  const _SlideHint({required this.reduced});

  final bool reduced;

  @override
  State<_SlideHint> createState() => _SlideHintState();
}

class _SlideHintState extends State<_SlideHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: ShaktiMotion.breathe,
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduced) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _SlideHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduced == oldWidget.reduced) return;
    if (widget.reduced) {
      _c.stop();
      _c.value = 0;
    } else {
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
    final t = Theme.of(context).textTheme;
    final hint = Column(
      children: [
        const Icon(Icons.keyboard_arrow_up_rounded, color: ShaktiColors.textLo),
        Text(
          'Swipe up to answer',
          style: t.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
    if (widget.reduced) return hint;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) =>
          Transform.translate(offset: Offset(0, -6 * _c.value), child: child),
      child: hint,
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.onSwipeUp,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onSwipeUp;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        onVerticalDragEnd: onSwipeUp == null
            ? null
            : (d) {
                if ((d.primaryVelocity ?? 0) < -200) onSwipeUp!();
              },
        child: Column(
          children: [
            Material(
              color: color,
              shape: const CircleBorder(),
              child: InkWell(
                key: ValueKey('fake-call-${label.toLowerCase()}'),
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox.square(
                  dimension: 72,
                  child: Icon(icon, color: ShaktiColors.textHi, size: 32),
                ),
              ),
            ),
            const SizedBox(height: ShaktiSpace.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InCall extends StatefulWidget {
  const _InCall({
    required this.caller,
    required this.seconds,
    required this.onEnd,
  });

  final String caller;
  final int seconds;
  final VoidCallback onEnd;

  @override
  State<_InCall> createState() => _InCallState();
}

class _InCallState extends State<_InCall> {
  bool _mute = false;
  bool _speaker = false;

  String get _clock {
    final m = widget.seconds ~/ 60;
    final s = widget.seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _toggle(IconData icon, String label, bool on, VoidCallback tap) =>
      Semantics(
        button: true,
        toggled: on,
        label: label,
        onTap: tap,
        excludeSemantics: true,
        child: Column(
          children: [
            Material(
              color: on ? ShaktiColors.textHi : ShaktiColors.surfaceHigh,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: tap,
                child: SizedBox.square(
                  dimension: 64,
                  child: Icon(
                    icon,
                    color: on ? ShaktiColors.bg : ShaktiColors.textHi,
                  ),
                ),
              ),
            ),
            const SizedBox(height: ShaktiSpace.xs),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ShaktiColors.bg,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(ShaktiSpace.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (constraints.maxHeight - 48).clamp(
                    0,
                    double.infinity,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: ShaktiSpace.lg),
                        _Avatar(name: widget.caller, size: 88),
                        const SizedBox(height: ShaktiSpace.md),
                        Text(
                          widget.caller,
                          textAlign: TextAlign.center,
                          style: t.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontFamily: ShaktiFonts.body,
                          ),
                        ),
                        const SizedBox(height: ShaktiSpace.xs),
                        Semantics(
                          label: 'Call time $_clock',
                          excludeSemantics: true,
                          child: Text(
                            _clock,
                            key: const ValueKey('fake-call-timer'),
                            style: t.titleMedium?.copyWith(
                              color: ShaktiColors.textLo,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        top: ShaktiSpace.xxl,
                        bottom: ShaktiSpace.lg,
                      ),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: ShaktiSpace.lg,
                            runSpacing: ShaktiSpace.lg,
                            alignment: WrapAlignment.center,
                            children: [
                              _toggle(
                                _mute
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                'Mute',
                                _mute,
                                () => setState(() => _mute = !_mute),
                              ),
                              _toggle(
                                Icons.dialpad_rounded,
                                'Keypad',
                                false,
                                () {},
                              ),
                              _toggle(
                                Icons.volume_up_rounded,
                                'Speaker',
                                _speaker,
                                () => setState(() => _speaker = !_speaker),
                              ),
                            ],
                          ),
                          const SizedBox(height: ShaktiSpace.xxl),
                          Semantics(
                            button: true,
                            label: 'End call',
                            onTap: widget.onEnd,
                            excludeSemantics: true,
                            child: Material(
                              color: ShaktiColors.sos,
                              shape: const CircleBorder(),
                              child: InkWell(
                                key: const ValueKey('fake-call-end'),
                                customBorder: const CircleBorder(),
                                onTap: widget.onEnd,
                                child: const SizedBox.square(
                                  dimension: 72,
                                  child: Icon(
                                    Icons.call_end_rounded,
                                    color: ShaktiColors.textHi,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
