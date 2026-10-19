import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/features/ai_guard/presentation/ai_guard_screen.dart';
import 'package:shakti/features/ai_guard/presentation/fir_screen.dart';
import 'package:shakti/features/contacts/presentation/contacts_screen.dart';
import 'package:shakti/features/de_escalation/presentation/fake_call_screen.dart';
import 'package:shakti/features/de_escalation/presentation/siren_screen.dart';
import 'package:shakti/features/escort/presentation/escort_screen.dart';
import 'package:shakti/features/evidence_vault/presentation/evidence_screen.dart';
import 'package:shakti/features/lock/presentation/lock_screen.dart';
import 'package:shakti/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shakti/features/panic/presentation/history_screen.dart';
import 'package:shakti/features/settings/presentation/safe_places_screen.dart';
import 'package:shakti/features/settings/presentation/settings_screen.dart';
import 'fakes/fakes.dart';

void main() {
  final screens = <String, Widget>{
    'onboarding': const OnboardingScreen(),
    'lock': const LockScreen(),
    'contacts': const ContactsScreen(),
    'escort': const EscortScreen(),
    'AI guardian': const AiGuardScreen(),
    'FIR': const FirScreen(),
    'fake call': const FakeCallScreen(),
    'siren': const SirenScreen(),
    'evidence': const EvidenceScreen(),
    'history': const HistoryScreen(),
    'safe places': const SafePlacesScreen(),
    'settings': const SettingsScreen(),
  };
  for (final entry in screens.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${entry.key} renders without exceptions at ${scale}x text', (tester) async {
        final f = Fakes();
        tester.view.physicalSize = const Size(400, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(overrides: f.overrides(), child: MaterialApp(
          theme: AppTheme.dark(),
          home: MediaQuery(data: MediaQueryData(size: const Size(400, 850), textScaler: TextScaler.linear(scale), disableAnimations: true), child: entry.value),
        )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      });
    }
  }
  testWidgets('manual siren starts and stops the platform port', (tester) async {
    final f = Fakes();
    await tester.pumpWidget(ProviderScope(overrides: f.overrides(), child: const MaterialApp(home: SirenScreen())));
    await tester.tap(find.text('Start siren'));
    await tester.pump();
    expect(f.siren.starts, 1);
    await tester.tap(find.text('Stop siren'));
    await tester.pump();
    expect(f.siren.stops, 1);
  });
}
