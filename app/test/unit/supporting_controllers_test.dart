import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/escort_timer.dart';
import 'package:shakti/domain/engines/pin_hasher.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/escort/application/escort_controller.dart';
import 'package:shakti/features/lock/application/lock_controller.dart';
import 'package:shakti/features/home/application/home_providers.dart';
import 'package:shakti/features/ai_guard/application/ai_controller.dart';
import 'package:shakti/features/safety_map/application/map_controller.dart';
import '../fakes/fakes.dart';

void main() {
  late Fakes f;
  late ProviderContainer c;
  setUp(() { f = Fakes(); c = ProviderContainer(overrides: f.overrides()); });
  tearDown(() => c.dispose());

  test('map uses cached havens offline and routes when available', () async {
    f.connectivity.online = false;
    f.havenCache.havens = List.of(f.havens.havens);
    final ctrl = c.read(mapControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await ctrl.load();
    expect(c.read(mapControllerProvider).fromCache, isTrue);
    expect(c.read(mapControllerProvider).havens, isNotEmpty);
    await ctrl.walkTo(f.havens.havens.first);
    expect(c.read(mapControllerProvider).bestRoute, isNotNull);
    f.routing.error = 'Offline';
    await ctrl.walkTo(f.havens.havens.first);
    expect(c.read(mapControllerProvider).routeError, isNotNull);
    expect(c.read(mapControllerProvider).bestRoute, isNull);
  });

  test('arrival cannot bypass PIN, correct PIN stops timer and notifies', () async {
    f.secureStore.map[pinHashKey] = await PinHasher.hash('2580', iterations: 1000);
    f.contacts.contacts = [const EmergencyContact(id: 'a', name: 'Guardian', phone: '+919876543210', priority: 1)];
    final ctrl = c.read(escortControllerProvider.notifier);
    await ctrl.start(const Duration(minutes: 5), destination: SafePlace(id: 'home', name: 'Home', point: FakeLocationService.defaultFix.point));
    ctrl.onFix(FakeLocationService.defaultFix);
    expect(await ctrl.answerArrival(checkIn: true), isFalse);
    expect(await ctrl.answerArrival(checkIn: true, pin: '0000'), isFalse);
    expect(c.read(escortControllerProvider).running, isTrue);
    expect(f.sms.sent, isEmpty);
    expect(await ctrl.answerArrival(checkIn: true, pin: '2580'), isTrue);
    expect(c.read(escortControllerProvider).status, EscortStatus.checkedIn);
    expect(f.sms.sent.single.$2, contains('Home'));
  });

  test('lock rejects five wrong attempts and unlocks only after timeout', () async {
    f.secureStore.map[PinKeys.primary] = await PinHasher.hash('2580', iterations: 1000);
    final lock = c.read(lockControllerProvider.notifier);
    for (var i = 0; i < 4; i++) { expect(await lock.unlock('0000'), UnlockResult.wrong); }
    expect(await lock.unlock('0000'), UnlockResult.lockedOut);
    expect(await lock.unlock('2580'), UnlockResult.lockedOut);
    f.clock.advance(const Duration(seconds: 31));
    expect(await lock.unlock('2580'), UnlockResult.ok);
  });

  test('AI failure preserves user message and exposes retry state', () async {
    f.ai.error = 'Offline';
    final ctrl = c.read(aiControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    await ctrl.send('Please help me get home');
    final state = c.read(aiControllerProvider);
    expect(state.typing, isFalse);
    expect(state.error, isNotNull);
    expect(state.messages.any((m) => m.role == ChatRole.user), isTrue);
    f.ai.error = null;
    f.ai.replies.add('Stay near trusted people.');
    await ctrl.retry();
    expect(c.read(aiControllerProvider).error, isNull);
    expect(c.read(aiControllerProvider).messages.last.role, ChatRole.assistant);
  });
}
