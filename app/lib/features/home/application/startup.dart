import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/router/gate.dart';
import '../../lock/application/lock_controller.dart';
import '../../panic/application/panic_controller.dart';
import '../../panic/application/panic_view_state.dart';
import '../../panic/application/trigger_hub.dart';
import 'home_providers.dart';

/// Keeps [appGateProvider] in step with the panic phase.
///
/// A visible (non-covert) countdown or active incident pins the router to
/// `/sos` via [AppGate.emergency], from any gate (Shield tab, a pushed route,
/// or the lock screen's "Emergency SOS"). When the incident is aborted or
/// acknowledged the gate goes back to where it was, so an SOS started from
/// the lock screen returns to the lock screen, not into the unlocked app.
/// Covert incidents and the decoy UI never change the gate.
final panicGateSyncProvider = Provider<void>((ref) {
  AppGate? before;
  ref.listen<PanicViewState>(panicControllerProvider, (prev, next) {
    final gate = ref.read(appGateProvider.notifier);
    final current = ref.read(appGateProvider);
    final live = next.phase == PanicPhase.countdown || next.phase == PanicPhase.active || next.phase == PanicPhase.resolved;

    if (live && !next.covert) {
      if (current == AppGate.emergency || current == AppGate.decoy) return;
      before = current;
      gate.set(AppGate.emergency);
      return;
    }
    if (next.phase == PanicPhase.idle && current == AppGate.emergency) {
      final back = before;
      before = null;
      gate.set(switch (back) {
        null || AppGate.loading || AppGate.emergency => AppGate.unlocked,
        final g => g,
      });
    }
  });
});

/// Decides the first gate, restores a live incident and arms the triggers.
/// `ShaktiApp` shows a splash until this completes.
final startupProvider = FutureProvider<void>((ref) async {
  ref.read(panicGateSyncProvider);
  final gate = ref.read(appGateProvider.notifier);

  AppGate first;
  try {
    final settings = await ref.read(settingsRepositoryProvider).load();
    final hasPin = await ref.read(secureStoreProvider).read(PinKeys.primary) != null;
    first = !settings.onboardingComplete
        ? AppGate.onboarding
        : hasPin
            ? AppGate.locked
            : AppGate.unlocked;
  } catch (_) {
    // Storage failed: never strand the user; the SOS button is on the lock
    // screen and the Shield tab alike.
    first = AppGate.locked;
  }
  gate.set(first);

  try {
    await ref.read(panicControllerProvider.notifier).restore();
  } catch (_) {}

  ref.read(triggerHubProvider);
  try {
    ref.read(lockControllerProvider.notifier).attachLifecycle();
  } catch (_) {
    // No binding (pure unit tests).
  }
});
