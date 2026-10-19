import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import '../../home/application/startup.dart';
import '../../panic/application/panic_controller.dart';
import '../application/lock_controller.dart';

/// PIN gate. The "Emergency SOS" button works without unlocking: starting an
/// SOS moves the gate to `emergency`, and it returns here afterwards.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _pad = GlobalKey<PinPadState>();
  String? _error;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeBiometric(auto: true));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _maybeBiometric({bool auto = false}) async {
    final settings = ref.read(liveSettingsProvider).value;
    if (settings == null || !settings.biometricUnlock) return;
    final ok = await ref.read(lockControllerProvider.notifier).unlockWithBiometrics();
    if (!ok && !auto && mounted) setState(() => _error = 'Fingerprint not recognised. Use your PIN');
  }

  void _startLockoutTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final left = ref.read(lockControllerProvider.notifier).lockoutRemaining;
      if (left == null) {
        t.cancel();
        setState(() => _error = null);
      } else {
        setState(() => _error = _lockoutText(left));
      }
    });
  }

  static String _lockoutText(Duration d) => 'Too many attempts. Try again in ${d.inSeconds + 1} s';

  Future<void> _submit(String pin) async {
    final result = await ref.read(lockControllerProvider.notifier).unlock(pin);
    if (!mounted) return;
    _pad.currentState?.clear();
    switch (result) {
      case UnlockResult.ok:
      case UnlockResult.decoy:
        // Both look identical to an onlooker; the router takes over.
        setState(() => _error = null);
      case UnlockResult.wrong:
        final left = LockController.maxAttempts - ref.read(lockControllerProvider).failedAttempts;
        setState(() => _error = 'Wrong PIN. $left ${left == 1 ? 'try' : 'tries'} left');
      case UnlockResult.lockedOut:
        final left = ref.read(lockControllerProvider.notifier).lockoutRemaining ?? LockController.baseLockout;
        setState(() => _error = _lockoutText(left));
        _startLockoutTicker();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(panicGateSyncProvider);
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(liveSettingsProvider).value;
    final lock = ref.watch(lockControllerProvider);
    final locked = ref.read(lockControllerProvider.notifier).lockoutRemaining != null;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Padding(
                padding: ShaktiSpace.screen,
                child: Column(
                  children: [
                    const SizedBox(height: ShaktiSpace.xl),
                    const ShaktiMark(size: 56),
                    const SizedBox(height: ShaktiSpace.md),
                    Semantics(header: true, child: Text('Enter PIN', style: t.headlineMedium)),
                    const SizedBox(height: ShaktiSpace.xs),
                    PinPad(
                      key: _pad,
                      onSubmit: _submit,
                      shuffle: false,
                      enabled: !lock.busy && !locked,
                      errorText: _error,
                    ),
                    if (settings?.biometricUnlock ?? false)
                      TextButton.icon(
                        onPressed: () => _maybeBiometric(),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use fingerprint'),
                      ),
                    const SizedBox(height: ShaktiSpace.lg),
                    _EmergencyButton(
                      onPressed: () => ref.read(panicControllerProvider.notifier).trigger(TriggerSource.hudTap),
                    ),
                    const SizedBox(height: ShaktiSpace.lg),
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

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Emergency SOS',
      hint: 'Works without your PIN. Starts a countdown you can cancel',
      excludeSemantics: true,
      child: OutlinedButton.icon(
        key: const ValueKey('lock-emergency'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ShaktiColors.sosGlow,
          side: BorderSide(color: ShaktiColors.sos.withValues(alpha: 0.7), width: 1.5),
          minimumSize: const Size.fromHeight(56),
        ),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('Emergency SOS'),
      ),
    );
  }
}

/// The Shakti logo mark: a rose flame held inside a shield, drawn in code so
/// it needs no asset.
class ShaktiMark extends StatelessWidget {
  const ShaktiMark({this.size = 48, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Shakti',
      image: true,
      child: CustomPaint(size: Size.square(size), painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..lineTo(w * 0.92, h * 0.18)
      ..cubicTo(w * 0.92, h * 0.62, w * 0.72, h * 0.86, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.28, h * 0.86, w * 0.08, h * 0.62, w * 0.08, h * 0.18)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeJoin = StrokeJoin.round
        ..color = ShaktiColors.textHi,
    );
    final flame = Path()
      ..moveTo(w * 0.5, h * 0.26)
      ..cubicTo(w * 0.68, h * 0.44, w * 0.7, h * 0.58, w * 0.62, h * 0.7)
      ..cubicTo(w * 0.56, h * 0.78, w * 0.44, h * 0.78, w * 0.38, h * 0.7)
      ..cubicTo(w * 0.3, h * 0.58, w * 0.36, h * 0.46, w * 0.5, h * 0.26)
      ..close();
    canvas.drawPath(
      flame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ShaktiColors.sosGlow, ShaktiColors.sos],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
