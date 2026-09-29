import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes.dart';

/// Top-level app mode that decides which part of the route tree is reachable.
enum AppGate {
  /// Settings still loading; stay where we are.
  loading,
  onboarding,
  locked,

  /// Duress PIN entered: only the decoy notes UI is reachable.
  decoy,
  unlocked,

  /// Unlocked and an incident is live: pin the user to the SOS screen.
  emergency,
}

/// Owned by the lock/onboarding/panic features, which call [set].
class AppGateController extends Notifier<AppGate> {
  @override
  AppGate build() => AppGate.loading;

  void set(AppGate gate) => state = gate;
}

final appGateProvider = NotifierProvider<AppGateController, AppGate>(AppGateController.new);

/// Pure redirect function so it can be unit-tested without a router.
String? gateRedirect(AppGate gate, String location) {
  switch (gate) {
    case AppGate.loading:
      return null;
    case AppGate.onboarding:
      return location == Routes.onboarding ? null : Routes.onboarding;
    case AppGate.locked:
      return location == Routes.lock ? null : Routes.lock;
    case AppGate.decoy:
      return location == Routes.decoy ? null : Routes.decoy;
    case AppGate.emergency:
      return location == Routes.sos ? null : Routes.sos;
    case AppGate.unlocked:
      const gated = {Routes.onboarding, Routes.lock, Routes.decoy};
      return gated.contains(location) ? Routes.home : null;
  }
}
