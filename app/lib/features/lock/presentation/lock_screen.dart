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

/// The shared shield-and-flame identity, using the brand master's 256-unit grid.
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
    canvas.save();
    canvas.scale(s.width / 256, s.height / 256);
    final shield = Path()
      ..moveTo(128, 30)
      ..lineTo(204, 59)
      ..lineTo(204, 120)
      ..cubicTo(204, 169, 169, 205, 128, 226)
      ..cubicTo(87, 205, 52, 169, 52, 120)
      ..lineTo(52, 59)
      ..close();
    canvas.drawPath(
      shield,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round
        ..color = ShaktiColors.textHi,
    );
    final flame = Path()
      ..moveTo(136, 75)
      ..cubicTo(143, 96, 165, 117, 159, 139)
      ..cubicTo(156, 157, 141, 171, 124, 170)
      ..cubicTo(102, 169, 89, 153, 93, 134)
      ..cubicTo(95, 122, 103, 113, 111, 104)
      ..cubicTo(108, 121, 115, 131, 124, 134)
      ..cubicTo(117, 116, 124, 91, 136, 75)
      ..close();
    canvas.drawPath(
      flame,
      Paint()..color = ShaktiColors.textHi,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
