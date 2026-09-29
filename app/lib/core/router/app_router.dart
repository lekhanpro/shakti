import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_guard/presentation/ai_guard_screen.dart';
import '../../features/ai_guard/presentation/fir_screen.dart';
import '../../features/contacts/presentation/contacts_screen.dart';
import '../../features/de_escalation/presentation/fake_call_screen.dart';
import '../../features/de_escalation/presentation/siren_screen.dart';
import '../../features/escort/presentation/escort_screen.dart';
import '../../features/evidence_vault/presentation/evidence_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/lock/presentation/decoy_notes_screen.dart';
import '../../features/lock/presentation/lock_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/panic/presentation/history_screen.dart';
import '../../features/panic/presentation/sos_screen.dart';
import '../../features/safety_map/presentation/safety_map_screen.dart';
import '../../features/settings/presentation/safe_places_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'app_shell.dart';
import 'gate.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Router with a redirect gate driven by [appGateProvider]:
/// onboarding -> lock -> (decoy | app). Active incidents force `/sos`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final gate = ValueNotifier<AppGate>(ref.read(appGateProvider));
  ref.listen<AppGate>(appGateProvider, (_, next) => gate.value = next);
  ref.onDispose(gate.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    refreshListenable: gate,
    redirect: (context, state) => gateRedirect(gate.value, state.matchedLocation),
    routes: [
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.lock, builder: (_, _) => const LockScreen()),
      GoRoute(path: Routes.decoy, builder: (_, _) => const DecoyNotesScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.map, builder: (_, _) => const SafetyMapScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.escort, builder: (_, _) => const EscortScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.guard, builder: (_, _) => const AiGuardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.settings, builder: (_, _) => const SettingsScreen())]),
        ],
      ),
      GoRoute(
        path: Routes.sos,
        pageBuilder: (_, _) => const NoTransitionPage(child: SosScreen()),
      ),
      GoRoute(path: Routes.contacts, builder: (_, _) => const ContactsScreen()),
      GoRoute(
        path: Routes.fakeCall,
        pageBuilder: (_, _) => const NoTransitionPage(child: FakeCallScreen()),
      ),
      GoRoute(path: Routes.siren, builder: (_, _) => const SirenScreen()),
      GoRoute(path: Routes.evidence, builder: (_, _) => const EvidenceScreen()),
      GoRoute(path: Routes.fir, builder: (_, _) => const FirScreen()),
      GoRoute(path: Routes.safePlaces, builder: (_, _) => const SafePlacesScreen()),
      GoRoute(path: Routes.history, builder: (_, _) => const HistoryScreen()),
    ],
  );
});
