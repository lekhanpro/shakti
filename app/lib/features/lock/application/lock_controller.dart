import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/gate.dart';
import '../../../domain/engines/pin_hasher.dart';
import '../../../domain/entities/entities.dart';
import '../../home/application/home_providers.dart';
import '../../panic/application/panic_controller.dart';

enum UnlockResult { ok, decoy, wrong, lockedOut }

class LockState {
  const LockState({this.failedAttempts = 0, this.lockouts = 0, this.lockedUntil, this.busy = false});

  /// Wrong attempts since the last success or lockout.
  final int failedAttempts;

  /// Number of lockouts so far; each one doubles the next lockout.
  final int lockouts;
  final DateTime? lockedUntil;
  final bool busy;

  LockState copyWith({int? failedAttempts, int? lockouts, DateTime? lockedUntil, bool clearLock = false, bool? busy}) =>
      LockState(
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockouts: lockouts ?? this.lockouts,
        lockedUntil: clearLock ? null : (lockedUntil ?? this.lockedUntil),
        busy: busy ?? this.busy,
      );
}

/// PIN unlock, duress PIN, brute-force lockout and background auto-lock.
class LockController extends Notifier<LockState> {
  static const maxAttempts = 5;
  static const baseLockout = Duration(seconds: 30);

  AppLifecycleListener? _lifecycle;
  DateTime? _backgroundedAt;

  @override
  LockState build() {
    ref.onDispose(() => _lifecycle?.dispose());
    return const LockState();
  }

  DateTime _now() => ref.read(clockProvider).now();

  /// Starts tracking foreground/background. Needs a Flutter binding, so it is
  /// called from app startup rather than [build].
  void attachLifecycle() {
    _lifecycle ??= AppLifecycleListener(onHide: onBackgrounded, onShow: () => unawaited(onResumed()));
  }

  void onBackgrounded() {
    _backgroundedAt ??= _now();
  }

  /// Locks the app when it was in the background longer than the timeout.
  Future<void> onResumed() async {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null || ref.read(appGateProvider) != AppGate.unlocked) return;
    final settings = await ref.read(settingsRepositoryProvider).load();
    final away = _now().difference(since);
    if (away < Duration(seconds: settings.lockTimeoutSeconds)) return;
    final hasPin = await ref.read(secureStoreProvider).read(PinKeys.primary) != null;
    if (hasPin && ref.mounted) ref.read(appGateProvider.notifier).set(AppGate.locked);
  }

  /// Remaining lockout, or null when PIN entry is allowed.
  Duration? get lockoutRemaining {
    final until = state.lockedUntil;
    if (until == null) return null;
    final left = until.difference(_now());
    return left > Duration.zero ? left : null;
  }

  Future<UnlockResult> unlock(String pin) async {
    if (lockoutRemaining != null) return UnlockResult.lockedOut;
    if (state.lockedUntil != null) state = state.copyWith(clearLock: true);

    state = state.copyWith(busy: true);
    final store = ref.read(secureStoreProvider);
    final primary = await store.read(PinKeys.primary);
    final decoy = await store.read(PinKeys.decoy);
    final isPrimary = primary != null && await PinHasher.verify(pin, primary);
    final isDecoy = !isPrimary && decoy != null && await PinHasher.verify(pin, decoy);
    if (!ref.mounted) return UnlockResult.wrong;

    if (isPrimary) {
      state = const LockState();
      ref.read(appGateProvider.notifier).set(AppGate.unlocked);
      return UnlockResult.ok;
    }
    if (isDecoy) {
      // Looks exactly like a success to anyone watching, while an SOS leaves
      // silently in the background.
      state = const LockState();
      ref.read(appGateProvider.notifier).set(AppGate.decoy);
      unawaited(ref.read(panicControllerProvider.notifier).trigger(TriggerSource.decoyPin, covert: true));
      return UnlockResult.decoy;
    }

    final attempts = state.failedAttempts + 1;
    if (attempts >= maxAttempts) {
      final lockout = baseLockout * (1 << state.lockouts);
      state = LockState(lockouts: state.lockouts + 1, lockedUntil: _now().add(lockout));
      return UnlockResult.lockedOut;
    }
    state = state.copyWith(failedAttempts: attempts, busy: false);
    return UnlockResult.wrong;
  }

  /// Biometric unlock (only offered when enabled in settings).
  Future<bool> unlockWithBiometrics() async {
    final bio = ref.read(biometricServiceProvider);
    try {
      if (!await bio.available) return false;
      final ok = await bio.authenticate('Unlock Shakti');
      if (ok && ref.mounted) {
        state = const LockState();
        ref.read(appGateProvider.notifier).set(AppGate.unlocked);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  void lockNow() => ref.read(appGateProvider.notifier).set(AppGate.locked);
}

final lockControllerProvider = NotifierProvider<LockController, LockState>(LockController.new);
