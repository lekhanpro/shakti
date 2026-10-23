import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/shakti_mark.dart';
import '../../../core/widgets/glass_surface.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeBiometric(auto: true),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _maybeBiometric({bool auto = false}) async {
    final settings = ref.read(liveSettingsProvider).value;
    if (settings == null || !settings.biometricUnlock) return;
    final ok = await ref
        .read(lockControllerProvider.notifier)
        .unlockWithBiometrics();
    if (!ok && !auto && mounted) {
      setState(() => _error = 'Fingerprint not recognised. Use your PIN');
    }
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

  static String _lockoutText(Duration d) =>
      'Too many attempts. Try again in ${d.inSeconds + 1} s';

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
        final left =
            LockController.maxAttempts -
            ref.read(lockControllerProvider).failedAttempts;
        setState(
          () => _error = 'Wrong PIN. $left ${left == 1 ? 'try' : 'tries'} left',
        );
      case UnlockResult.lockedOut:
        final left =
            ref.read(lockControllerProvider.notifier).lockoutRemaining ??
            LockController.baseLockout;
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
    final locked =
        ref.read(lockControllerProvider.notifier).lockoutRemaining != null;

    return Scaffold(
      body: ShaktiBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Padding(
                  padding: ShaktiSpace.screen,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        children: [
                          const SizedBox(height: ShaktiSpace.lg),
                          GlassSurface(
                            radius: ShaktiRadius.md,
                            color: context.shakti.accentContainer,
                            padding: const EdgeInsets.all(20),
                            child: ShaktiMark(
                              size: 48,
                              color: context.shakti.lilac,
                            ),
                          ),
                          const SizedBox(height: ShaktiSpace.lg),
                          Semantics(
                            header: true,
                            child: Text(
                              'Welcome back',
                              style: t.headlineLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: ShaktiSpace.xs),
                          Text(
                            'Enter PIN',
                            style: t.bodyLarge?.copyWith(
                              color: context.shakti.textMid,
                            ),
                          ),
                          const SizedBox(height: ShaktiSpace.md),
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
                          Text(
                            'Your emergency button is always available here.',
                            textAlign: TextAlign.center,
                            style: t.bodySmall?.copyWith(
                              color: context.shakti.textLo,
                            ),
                          ),
                          const SizedBox(height: ShaktiSpace.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ShaktiSpace.lg,
            ShaktiSpace.sm,
            ShaktiSpace.lg,
            ShaktiSpace.md,
          ),
          child: _EmergencyButton(
            onPressed: () => ref
                .read(panicControllerProvider.notifier)
                .trigger(TriggerSource.hudTap),
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
      onTap: onPressed,
      excludeSemantics: true,
      child: OutlinedButton.icon(
        key: const ValueKey('lock-emergency'),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.shakti.sosGlow,
          backgroundColor: context.shakti.surface,
          side: BorderSide(
            color: context.shakti.sos.withValues(alpha: 0.7),
            width: 1.5,
          ),
          minimumSize: const Size.fromHeight(56),
        ),
        icon: const Icon(Icons.sos_rounded),
        label: const Text('Emergency SOS'),
      ),
    );
  }
}
