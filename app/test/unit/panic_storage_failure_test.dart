import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/panic/application/panic_controller.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';

import '../fakes/fakes.dart';

void main() {
  late Fakes f;
  late FakeSettingsRepository settings;
  late ProviderContainer container;

  setUp(() {
    f = Fakes();
    settings = f.settings;
    settings.failLoad = true;
    f.contacts.contacts = [
      const EmergencyContact(
        id: 'guardian', name: 'Guardian',
        phone: '+919876543210', priority: 1,
      ),
    ];
    container = ProviderContainer(overrides: f.overrides());
  });

  tearDown(() => container.dispose());

  test('settings storage failure still saves an SOS and attempts carrier SMS', () {
    fakeAsync((async) {
      final controller = container.read(panicControllerProvider.notifier);
      controller.trigger(TriggerSource.hudTap);
      async.flushMicrotasks();
      expect(container.read(panicControllerProvider).phase, PanicPhase.countdown);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();

      final state = container.read(panicControllerProvider);
      expect(state.phase, PanicPhase.active);
      expect(f.incidents.incidents, hasLength(1));
      expect(f.sms.sent, hasLength(1));
      expect(state.report!.status(DispatchChannel.sms), ChannelStatus.ok);
      expect(f.siren.starts, 0);
      expect(f.cloud.calls, isEmpty);
      expect(state.report!.status(DispatchChannel.audio), ChannelStatus.skipped);
    });
  });

  test('a duress trigger remains immediate and silent when settings fail', () {
    fakeAsync((async) {
      container.read(panicControllerProvider.notifier)
          .trigger(TriggerSource.decoyPin, covert: true);
      async.flushMicrotasks();
      expect(container.read(panicControllerProvider).phase, PanicPhase.active);
      expect(f.sms.sent, hasLength(1));
      expect(f.siren.starts, 0);
      expect(f.haptics.heavies + f.haptics.ticks + f.haptics.sosPatterns, 0);
      expect(f.incidents.incidents.single.covert, isTrue);
    });
  });

  test('a later settings failure preserves previously loaded user choices', () {
    fakeAsync((async) {
      settings.failLoad = false;
      settings.settings = const SafetySettings(
        countdownSeconds: 3, sirenOnSos: false,
        recordAudio: false, cloudEnabled: false,
      );
      final controller = container.read(panicControllerProvider.notifier);
      controller.trigger(TriggerSource.hudTap);
      async.flushMicrotasks();
      settings.failLoad = true;
      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(f.sms.sent, hasLength(1));
      expect(f.cloud.calls, isEmpty);
      expect(f.siren.starts, 0);
      expect(container.read(panicControllerProvider).phase, PanicPhase.active);
    });
  });

  test('aborting completes the pending trigger without sending an alert', () {
    fakeAsync((async) {
      settings.failLoad = false;
      final controller = container.read(panicControllerProvider.notifier);
      var completed = false;
      controller.trigger(TriggerSource.hudTap).then((_) => completed = true);
      async.flushMicrotasks();
      controller.abort();
      async.flushMicrotasks();
      expect(completed, isTrue);
      async.elapse(const Duration(seconds: 10));
      expect(f.sms.sent, isEmpty);
      expect(f.incidents.incidents, isEmpty);
    });
  });
}
