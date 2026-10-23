import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/di/providers.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/de_escalation/application/ringtone_player.dart';
import 'package:shakti/features/de_escalation/presentation/fake_call_screen.dart';

import '../fakes/fakes.dart';

class _SlowSettings extends FakeSettingsRepository {
  final releaseSave = Completer<void>();
  SafetySettings? pending;

  @override
  Future<void> save(SafetySettings settings) async {
    pending = settings;
    await releaseSave.future;
    await super.save(settings);
  }
}

class _Ringtone implements RingtonePlayer {
  int starts = 0;
  int stops = 0;

  @override
  Future<void> startLoop() async => starts++;

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

void main() {
  for (final delay in [0, 10]) {
    testWidgets(
      '${delay == 0 ? 'Ring now' : 'Scheduled call'} rings while preference saving is stalled',
      (tester) async {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakes = Fakes();
        final settings = _SlowSettings();
        final ring = _Ringtone();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...fakes.overrides().where(
                (override) => override.origin != settingsRepositoryProvider,
              ),
              settingsRepositoryProvider.overrideWithValue(settings),
              ringtonePlayerProvider.overrideWithValue(ring),
            ],
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const MediaQuery(
                data: MediaQueryData(
                  size: Size(420, 900),
                  disableAnimations: true,
                ),
                child: FakeCallScreen(callerName: 'Amma'),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.tap(find.text(delay == 0 ? 'Now' : '10 s'));
        await tester.pump();
        await tester.tap(find.text(delay == 0 ? 'Ring now' : 'Schedule call'));
        await tester.pump();

        expect(settings.pending?.fakeCallerName, 'Amma');
        expect(settings.pending?.fakeCallDelaySeconds, delay);
        expect(settings.releaseSave.isCompleted, isFalse);
        expect(settings.saveCount, 0);

        if (delay > 0) {
          expect(ring.starts, 0);
          expect(find.text('seconds until Amma calls'), findsOneWidget);
          await tester.pump(const Duration(seconds: 11));
        }
        expect(ring.starts, 1);

        // Answer and End also remain available while the optional write waits.
        await tester.tap(find.bySemanticsLabel('Answer'));
        await tester.pump();
        expect(ring.stops, greaterThanOrEqualTo(1));
        expect(find.byKey(const ValueKey('fake-call-timer')), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('End call'));
        await tester.pump();
        expect(find.text('Who is calling'), findsOneWidget);

        settings.releaseSave.complete();
        await tester.pump();
        expect(settings.saveCount, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
