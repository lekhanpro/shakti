import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/router/gate.dart';
import 'package:shakti/core/theme/app_theme.dart';
import 'package:shakti/domain/engines/pin_hasher.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/contacts/presentation/contact_form.dart';
import 'package:shakti/features/de_escalation/application/ringtone_player.dart';
import 'package:shakti/features/de_escalation/presentation/fake_call_screen.dart';
import 'package:shakti/features/home/application/home_providers.dart';
import 'package:shakti/features/home/presentation/home_screen.dart';
import 'package:shakti/features/lock/presentation/lock_screen.dart';
import 'package:shakti/features/panic/application/panic_controller.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';
import 'package:shakti/features/panic/presentation/sos_screen.dart';

import '../fakes/fakes.dart';

class _FakeRingtone implements RingtonePlayer {
  int starts = 0;
  int stops = 0;
  @override
  Future<void> startLoop() async => starts++;
  @override
  Future<void> stop() async => stops++;
  @override
  Future<void> dispose() async {}
}

/// Pumps [child] inside a scope backed by [f] and returns the container.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  Fakes f,
  Widget child, {
  List<Override> extra = const [],
}) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(overrides: [...f.overrides(), ...extra]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.dark(),
      home: MediaQuery(
        data: const MediaQueryData(size: Size(420, 900), disableAnimations: true),
        child: child,
      ),
    ),
  ));
  await tester.pump();
  return container;
}

void main() {
  group('SOS HUD (A2)', () {
    testWidgets('has an SOS semantics label, is at least 220 dp, and a tap starts the countdown', (tester) async {
      final f = Fakes();
      final c = await _pump(tester, f, const HomeScreen());
      expect(find.bySemanticsLabel('Send SOS'), findsOneWidget);
      final size = tester.getSize(find.byKey(const ValueKey('sos-button')));
      expect(size.width, greaterThanOrEqualTo(220));

      await tester.tap(find.byKey(const ValueKey('sos-button')));
      await tester.pump();
      expect(c.read(panicControllerProvider).phase, PanicPhase.countdown);

      c.read(panicControllerProvider.notifier).abort();
      await tester.pump();
    });
  });

  group('Countdown (A3)', () {
    testWidgets('ticks once a second with a haptic each tick, and Cancel aborts with nothing sent', (tester) async {
      final f = Fakes();
      final c = await _pump(tester, f, const SosScreen());
      // trigger() resolves only after the countdown, so drive it with pumps.
      unawaited(c.read(panicControllerProvider.notifier).trigger(TriggerSource.hudTap));
      await tester.pump();
      await tester.pump();
      final total = c.read(panicControllerProvider).totalSeconds;
      expect(find.bySemanticsLabel('$total seconds left'), findsOneWidget);
      final ticksBefore = f.haptics.ticks;

      await tester.pump(const Duration(seconds: 1));
      expect(c.read(panicControllerProvider).secondsLeft, total - 1);
      expect(find.bySemanticsLabel('${total - 1} seconds left'), findsOneWidget);
      expect(f.haptics.ticks, greaterThan(ticksBefore));

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(c.read(panicControllerProvider).phase, PanicPhase.idle);
      await tester.pump(Duration(seconds: total + 1));
      expect(f.sms.sent, isEmpty);
    });
  });

  group('Contact form', () {
    Future<ContactDraft?> fill(
      WidgetTester tester,
      String name,
      String phone, {
      Set<String> existing = const {},
    }) async {
      ContactDraft? saved;
      await _pump(
        tester,
        Fakes(),
        Scaffold(
          body: SingleChildScrollView(
            child: ContactForm(existingPhones: existing, onSubmit: (d) => saved = d),
          ),
        ),
      );
      await tester.enterText(find.byKey(const ValueKey('contact-name')), name);
      await tester.enterText(find.byKey(const ValueKey('contact-phone')), phone);
      await tester.tap(find.byKey(const ValueKey('contact-save')));
      await tester.pump();
      return saved;
    }

    testWidgets('trims the name and normalises a valid Indian number', (tester) async {
      final d = await fill(tester, '  Asha  ', '98450 12345');
      expect(d, isNotNull);
      expect(d!.name, 'Asha');
      expect(d.phone, '+919845012345');
    });

    testWidgets('rejects an empty name and an invalid number', (tester) async {
      expect(await fill(tester, '', '123'), isNull);
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.textContaining('valid mobile number'), findsOneWidget);
    });

    testWidgets('rejects helpline numbers', (tester) async {
      expect(await fill(tester, 'Police', '112'), isNull);
      expect(find.textContaining('Helplines are built in'), findsOneWidget);
    });

    testWidgets('rejects a number that is already saved', (tester) async {
      expect(await fill(tester, 'Asha', '9845012345', existing: {'+919845012345'}), isNull);
      expect(find.textContaining('already a trusted contact'), findsOneWidget);
    });
  });

  group('Lock screen (S1/S2)', () {
    Future<(Fakes, ProviderContainer)> setUpLock(WidgetTester tester) async {
      final f = Fakes();
      await tester.runAsync(() async {
        f.secureStore.map[PinKeys.primary] = await PinHasher.hash('2468', iterations: 1000);
        f.secureStore.map[PinKeys.decoy] = await PinHasher.hash('1357', iterations: 1000);
      });
      final c = await _pump(tester, f, const LockScreen());
      c.read(appGateProvider.notifier).set(AppGate.locked);
      await tester.pump();
      return (f, c);
    }

    Future<void> submit(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.byKey(ValueKey('pin-$d')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('pin-submit')));
      // PBKDF2 verification runs on a real isolate, outside the fake clock.
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
    }

    testWidgets('the primary PIN unlocks', (tester) async {
      final (_, c) = await setUpLock(tester);
      await submit(tester, '2468');
      expect(c.read(appGateProvider), AppGate.unlocked);
    });

    testWidgets('a wrong PIN stays locked and shows the remaining tries', (tester) async {
      final (_, c) = await setUpLock(tester);
      await submit(tester, '0000');
      expect(c.read(appGateProvider), AppGate.locked);
      expect(find.text('Wrong PIN. 4 tries left'), findsOneWidget);
    });

    testWidgets('the decoy PIN opens the decoy UI and fires a silent covert SOS', (tester) async {
      final (f, c) = await setUpLock(tester);
      await submit(tester, '1357');
      expect(c.read(appGateProvider), AppGate.decoy);
      final s = c.read(panicControllerProvider);
      expect(s.covert, isTrue);
      expect(s.phase, isNot(PanicPhase.countdown));
      expect(f.siren.starts, 0);

      // End the incident so its breadcrumb timer does not outlive the test.
      await c.read(panicControllerProvider.notifier).resolve(falseAlarm: true);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 30));
    });
  });

  group('Fake call (E1)', () {
    testWidgets('Ring now plays the ringtone, Answer starts the call clock, End returns to setup', (tester) async {
      final ring = _FakeRingtone();
      await _pump(
        tester,
        Fakes(),
        const FakeCallScreen(callerName: 'Amma'),
        extra: [ringtonePlayerProvider.overrideWithValue(ring)],
      );
      await tester.tap(find.text('Now'));
      await tester.pump();
      await tester.tap(find.text('Ring now'));
      await tester.pump();
      await tester.pump();
      expect(ring.starts, 1);
      expect(find.text('Amma'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Answer'));
      await tester.pump();
      expect(ring.stops, greaterThanOrEqualTo(1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.bySemanticsLabel(RegExp(r'^Call time 00:0[12]$')), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('End call'));
      await tester.pump();
      expect(find.text('Who is calling'), findsOneWidget);
    });

    testWidgets('a scheduled call waits for the delay before ringing', (tester) async {
      final ring = _FakeRingtone();
      await _pump(
        tester,
        Fakes(),
        const FakeCallScreen(callerName: 'Amma'),
        extra: [ringtonePlayerProvider.overrideWithValue(ring)],
      );
      await tester.tap(find.text('10 s'));
      await tester.pump();
      await tester.tap(find.text('Schedule call'));
      await tester.pump();
      await tester.pump();
      expect(ring.starts, 0);
      expect(find.text('seconds until Amma calls'), findsOneWidget);
      await tester.pump(const Duration(seconds: 11));
      expect(ring.starts, 1);
      await tester.tap(find.bySemanticsLabel('Decline'));
      await tester.pump();
    });
  });
}
