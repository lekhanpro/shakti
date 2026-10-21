import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/panic/application/panic_controller.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';

import '../fakes/fakes.dart';

const _a = EmergencyContact(id: 'a', name: 'Amma', phone: '+919845012345', priority: 1);
const _b = EmergencyContact(id: 'b', name: 'Riya', phone: '+919845067890', priority: 2);
const _paused = EmergencyContact(id: 'c', name: 'Old', phone: '+919845000000', priority: 3, isActive: false);

void main() {
  late Fakes f;
  late ProviderContainer c;

  setUp(() {
    f = Fakes();
    f.contacts.contacts = [_a, _b, _paused];
    c = ProviderContainer(overrides: f.overrides());
  });

  tearDown(() => c.dispose());

  PanicController ctrl() => c.read(panicControllerProvider.notifier);
  PanicViewState st() => c.read(panicControllerProvider);

  /// Triggers and runs the fake clock past the countdown and the pipeline.
  void runSos(FakeAsync async, {TriggerSource source = TriggerSource.hudTap, bool covert = false}) {
    c.listen(panicControllerProvider, (_, _) {});
    ctrl().trigger(source, covert: covert);
    async.flushMicrotasks();
    async.elapse(const Duration(seconds: 6));
    async.flushMicrotasks();
  }

  test('countdown then active sends SMS to every active contact', () {
    fakeAsync((async) {
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().trigger(TriggerSource.hudTap);
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.countdown);
      expect(st().secondsLeft, 5);

      async.elapse(const Duration(seconds: 2));
      expect(st().secondsLeft, 3);
      expect(f.sms.sent, isEmpty, reason: 'nothing leaves during the grace window');

      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.active);
      expect(f.sms.sent, hasLength(1));
      expect(f.sms.sent.single.$1, unorderedEquals([_a.phone, _b.phone]));
      expect(f.sms.sent.single.$2, contains('maps.google'));
      final r = st().report!;
      expect(r.status(DispatchChannel.sms), ChannelStatus.ok);
      expect(r.smsRecipients, 2);
      expect(r.status(DispatchChannel.localSave), ChannelStatus.ok);
      expect(f.incidents.incidents.single.status, IncidentStatus.active);
      expect(f.siren.starts, 1);
    });
  });

  test('abort during countdown sends nothing', () {
    fakeAsync((async) {
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().trigger(TriggerSource.hudTap);
      async.elapse(const Duration(seconds: 2));
      ctrl().abort();
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.idle);
      expect(f.sms.sent, isEmpty);
      expect(f.incidents.incidents, isEmpty);
      expect(f.cloud.calls, isEmpty);
      expect(f.haptics.cancels, 1);
    });
  });

  test('abort completes the pending trigger future', () {
    fakeAsync((async) {
      var completed = false;
      ctrl().trigger(TriggerSource.hudTap).then((_) => completed = true);
      async.flushMicrotasks();
      ctrl().abort();
      async.flushMicrotasks();
      expect(completed, isTrue);
    });
  });

  test('late SMS failure cannot modify a newer incident', () {
    fakeAsync((async) {
      final pending = Completer<Result<int>>();
      f.sms.pendingResult = pending;
      ctrl().trigger(TriggerSource.decoyPin, covert: true);
      async.flushMicrotasks();
      final oldId = st().incident!.id;
      ctrl().resolve();
      async.flushMicrotasks();
      ctrl().acknowledge();
      f.sms.pendingResult = null;
      ctrl().trigger(TriggerSource.decoyPin, covert: true);
      async.flushMicrotasks();
      final newId = st().incident!.id;
      expect(newId, isNot(oldId));
      pending.complete(const Err('Old send failed'));
      async.flushMicrotasks();
      expect(st().incident!.id, newId);
      expect(st().report!.status(DispatchChannel.sms), ChannelStatus.ok);
    });
  });

  test('a double trigger is ignored', () {
    fakeAsync((async) {
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().trigger(TriggerSource.hudTap);
      async.elapse(const Duration(seconds: 1));
      ctrl().trigger(TriggerSource.shake);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      ctrl().trigger(TriggerSource.triplePower);
      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(st().source, TriggerSource.hudTap);
      expect(f.incidents.incidents, hasLength(1));
      expect(f.sms.sent, hasLength(1));
    });
  });

  test('zero contacts: SMS fails with a note, other channels still run', () {
    fakeAsync((async) {
      f.contacts.contacts = [];
      runSos(async);
      final r = st().report!;
      expect(r.status(DispatchChannel.sms), ChannelStatus.failed);
      expect(r.notes[DispatchChannel.sms], isNotEmpty);
      expect(r.status(DispatchChannel.localSave), ChannelStatus.ok);
      expect(r.status(DispatchChannel.siren), ChannelStatus.ok);
      expect(r.status(DispatchChannel.cloud), ChannelStatus.ok);
      expect(f.cloud.calls, hasLength(1));
      expect(f.audio.recordedIncidentIds, hasLength(1));
    });
  });

  test('location Err still sends the SMS with "Location unavailable"', () {
    fakeAsync((async) {
      f.location.error = 'Permission denied';
      runSos(async);
      expect(f.sms.sent.single.$2, contains('Location unavailable'));
      expect(st().report!.status(DispatchChannel.location), ChannelStatus.failed);
      expect(st().report!.status(DispatchChannel.sms), ChannelStatus.ok);
    });
  });

  test('a stalled GPS fix does not delay carrier SMS', () {
    fakeAsync((async) {
      f.location.fix = null;
      f.location.delay = const Duration(minutes: 1);
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().trigger(TriggerSource.hudTap);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 5, milliseconds: 100));
      async.flushMicrotasks();
      expect(f.sms.sent, hasLength(1));
      expect(f.sms.sent.single.$2, contains('Location unavailable'));
      expect(st().report!.status(DispatchChannel.location), ChannelStatus.running);
    });
  });

  test('offline leaves cloud pending, then connectivity triggers the dispatch', () {
    fakeAsync((async) {
      f.connectivity.online = false;
      runSos(async);
      expect(st().report!.status(DispatchChannel.cloud), ChannelStatus.pending);
      expect(f.cloud.calls, isEmpty);
      expect(f.sms.sent, hasLength(1), reason: 'SMS never waits for the network');

      f.connectivity.set(true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      expect(f.cloud.calls, hasLength(1));
      expect(st().report!.status(DispatchChannel.cloud), ChannelStatus.ok);
      expect(f.sync.flushCount, greaterThanOrEqualTo(1));
    });
  });

  test('covert skips the countdown, the siren and haptics', () {
    fakeAsync((async) {
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().trigger(TriggerSource.decoyPin, covert: true);
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.active);
      expect(st().covert, isTrue);
      async.elapse(const Duration(seconds: 1));
      expect(f.sms.sent, hasLength(1));
      expect(f.siren.starts, 0);
      expect(f.haptics.heavies + f.haptics.ticks + f.haptics.sosPatterns, 0);
      expect(st().report!.status(DispatchChannel.siren), ChannelStatus.skipped);
      expect(f.incidents.incidents.single.covert, isTrue);
    });
  });

  test('resolve sends the safe SMS and saves the resolved status', () {
    fakeAsync((async) {
      runSos(async);
      ctrl().resolve();
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      expect(st().phase, PanicPhase.resolved);
      expect(f.sms.sent, hasLength(2));
      expect(f.sms.sent.last.$2, contains('safe'));
      expect(f.incidents.incidents.single.status, IncidentStatus.resolved);
      expect(f.incidents.incidents.single.resolvedAt, isNotNull);
      expect(f.siren.stops, greaterThanOrEqualTo(1));
      expect(f.cloud.resolvedCalls, hasLength(1));

      ctrl().acknowledge();
      expect(st().phase, PanicPhase.idle);
    });
  });

  test('false alarm saves the falseAlarm status', () {
    fakeAsync((async) {
      runSos(async);
      ctrl().resolve(falseAlarm: true);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 10));
      expect(f.incidents.incidents.single.status, IncidentStatus.falseAlarm);
    });
  });

  test('restore() rebuilds the active state from the repository', () {
    fakeAsync((async) {
      final open = Incident(
        id: 'i1',
        source: TriggerSource.triplePower,
        status: IncidentStatus.active,
        createdAt: DateTime(2026, 9, 29, 9, 55),
        shareToken: 'tok',
        smsDispatched: true,
      );
      f.incidents.incidents = [open];
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().restore();
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.active);
      expect(st().source, TriggerSource.triplePower);
      expect(st().incident!.id, 'i1');
      expect(st().report!.status(DispatchChannel.sms), ChannelStatus.ok);
      // The cloud alert never went out, so restore retries it while online.
      expect(f.cloud.calls.map((i) => i.id), ['i1']);
      expect(st().report!.status(DispatchChannel.cloud), ChannelStatus.ok);

      // Breadcrumbs resume.
      async.elapse(const Duration(seconds: 11));
      async.flushMicrotasks();
      expect(f.incidents.allBreadcrumbs, isNotEmpty);
    });
  });

  test('restore() ignores a resolved incident', () {
    fakeAsync((async) {
      f.incidents.incidents = [
        Incident(
          id: 'old',
          source: TriggerSource.hudTap,
          status: IncidentStatus.resolved,
          createdAt: DateTime(2026, 9, 28),
          shareToken: 't',
        ),
      ];
      c.listen(panicControllerProvider, (_, _) {});
      ctrl().restore();
      async.flushMicrotasks();
      expect(st().phase, PanicPhase.idle);
    });
  });
}
