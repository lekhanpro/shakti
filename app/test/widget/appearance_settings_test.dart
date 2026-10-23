import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/settings/presentation/settings_screen.dart';

import '../fakes/fakes.dart';

void main() {
  testWidgets(
    'appearance choices persist, announce selection and fit narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final fakes = Fakes();
      fakes.settings.settings = const SafetySettings(
        userName: 'Annapoorna Krishnamurthy',
        stealthMode: true,
        recordAudio: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: fakes.overrides(),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(320, 850),
                textScaler: TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: SettingsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      Future<void> reveal(AppearancePreference choice) async {
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('appearance-${choice.name}')),
          140,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      await reveal(AppearancePreference.light);
      final light = find.byKey(const ValueKey('appearance-light'));
      expect(
        tester.getSemantics(light).getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );

      for (final choice in [
        AppearancePreference.dark,
        AppearancePreference.system,
        AppearancePreference.light,
      ]) {
        await reveal(choice);
        final tile = find.byKey(ValueKey('appearance-${choice.name}'));
        expect(tester.getSize(tile).height, greaterThanOrEqualTo(48));
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(fakes.settings.settings.appearance, choice);
        expect(fakes.settings.settings.stealthMode, isTrue);
        expect(fakes.settings.settings.recordAudio, isFalse);
        expect(
          tester
              .getSemantics(tile)
              .getSemanticsData()
              .flagsCollection
              .isChecked,
          CheckedState.isTrue,
        );
        expect(tester.takeException(), isNull);
      }
      expect(fakes.settings.saveCount, 3);
      semantics.dispose();
    },
  );
}
