import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/app.dart';
import 'package:shakti/domain/entities/safety_settings.dart';
import 'package:shakti/features/home/presentation/home_screen.dart';

import '../fakes/fakes.dart';

void main() {
  testWidgets('saved appearance updates the running app and follows system brightness', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final f = Fakes();
    f.settings.settings = const SafetySettings(onboardingComplete: true);
    await tester.pumpWidget(ProviderScope(overrides: f.overrides(), child: const ShaktiApp()));
    Future<void> settleAppearance() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
    await settleAppearance();
    await settleAppearance();
    Brightness brightness() => Theme.of(tester.element(find.byType(HomeScreen))).brightness;
    expect(brightness(), Brightness.light);
    await f.settings.save(f.settings.settings.copyWith(appearance: AppearancePreference.dark));
    await settleAppearance();
    expect(brightness(), Brightness.dark);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await f.settings.save(f.settings.settings.copyWith(appearance: AppearancePreference.system));
    await settleAppearance();
    expect(brightness(), Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await settleAppearance();
    expect(brightness(), Brightness.dark);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
