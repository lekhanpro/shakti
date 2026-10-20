import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/escort_timer.dart';
import 'package:shakti/domain/engines/pin_hasher.dart';
import 'package:shakti/features/escort/application/escort_controller.dart';

import '../fakes/fakes.dart';

void main() {
  late Fakes f;
  late ProviderContainer container;

  setUp(() async {
    f = Fakes();
    f.secureStore.map[pinHashKey] = await PinHasher.hash('2580', iterations: 1000);
    container = ProviderContainer(overrides: f.overrides());
  });
  tearDown(() => container.dispose());

  test('a pending PIN cannot check in a cancelled walk', () async {
    final controller = container.read(escortControllerProvider.notifier);
    await controller.start(const Duration(minutes: 5));
    final pending = controller.checkIn('2580');
    controller.reset();

    expect(await pending, isFalse);
    expect(container.read(escortControllerProvider).status, EscortStatus.idle);
  });

  test('a PIN from the previous walk cannot end a newly started walk', () async {
    final controller = container.read(escortControllerProvider.notifier);
    await controller.start(const Duration(minutes: 5));
    final pending = controller.checkIn('2580');
    controller.reset();
    await controller.start(const Duration(minutes: 10));

    expect(await pending, isFalse);
    expect(container.read(escortControllerProvider).status, EscortStatus.running);
    expect(container.read(escortControllerProvider).total, const Duration(minutes: 10));
  });

  test('a deadline reached during verification expires even before the next tick', () async {
    final controller = container.read(escortControllerProvider.notifier);
    await controller.start(const Duration(minutes: 1));
    final pending = controller.checkIn('2580');
    f.clock.advance(const Duration(minutes: 2));

    expect(await pending, isFalse);
    expect(container.read(escortControllerProvider).status, EscortStatus.expired);
    expect(f.sms.sent, isEmpty, reason: 'a late PIN must not emit a safe-arrival message');
  });

  test('a valid PIN before the deadline still completes the current walk', () async {
    final controller = container.read(escortControllerProvider.notifier);
    await controller.start(const Duration(minutes: 5));

    expect(await controller.checkIn('2580'), isTrue);
    expect(container.read(escortControllerProvider).status, EscortStatus.checkedIn);
  });
}
