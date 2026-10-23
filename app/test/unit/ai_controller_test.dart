import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/di/providers.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/domain/services/services.dart';
import 'package:shakti/features/ai_guard/application/ai_controller.dart';

import '../fakes/fakes.dart';

class _DelayedAi implements AiService {
  final reply = Completer<Result<String>>();

  @override
  Future<Result<String>> chat(List<ChatMessage> history, {GeoPoint? location}) => reply.future;

  @override
  Future<Result<String>> draftFir(FirInput input) => reply.future;
}

void main() {
  late Fakes f;
  late ProviderContainer container;

  setUp(() {
    f = Fakes();
    container = ProviderContainer(overrides: f.overrides());
  });
  tearDown(() => container.dispose());

  test('unconfigured builds are reported truthfully and chat does not collect location', () async {
    final controller = container.read(aiControllerProvider.notifier);
    expect(container.read(aiControllerProvider).isConfigured, isFalse);
    await controller.send('Hello');
    expect(f.location.currentFixCalls, 0);
    expect(f.ai.locations.single, isNull);
  });

  test('location is approximate and only shared while explicitly enabled', () async {
    final controller = container.read(aiControllerProvider.notifier);
    controller.setLocationEnabled(true);
    await controller.send('Where can I find people?');
    expect(f.location.currentFixCalls, 1);
    expect(f.ai.locations.single, const GeoPoint(12.97, 77.59));
    controller.setLocationEnabled(false);
    await controller.send('Thanks');
    expect(f.location.currentFixCalls, 1);
    expect(f.ai.locations.last, isNull);
  });

  test('rate limits and backend configuration failures retain their useful message', () async {
    f.ai.error = 'Too many requests. Please wait a minute';
    await container.read(aiControllerProvider.notifier).send('Hello');
    expect(container.read(aiControllerProvider).error, f.ai.error);
    expect(container.read(aiControllerProvider).typing, isFalse);
    f.ai.error = null;
    await container.read(aiControllerProvider.notifier).retry();
    expect(container.read(aiControllerProvider).error, isNull);
  });

  test('oversize input is not saved or sent', () async {
    await container.read(aiControllerProvider.notifier).send('x' * 2001);
    expect(f.chat.messages, isEmpty);
    expect(f.ai.chatCalls, isEmpty);
    expect(container.read(aiControllerProvider).error, contains('2,000'));
  });

  test('clearing chat prevents a pending reply from restoring the conversation', () async {
    container.dispose();
    final delayed = _DelayedAi();
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(f.chat),
        locationServiceProvider.overrideWithValue(f.location),
        clockProvider.overrideWithValue(f.clock),
        aiServiceProvider.overrideWithValue(delayed),
        aiBackendConfiguredProvider.overrideWithValue(true),
      ],
    );
    final controller = container.read(aiControllerProvider.notifier);
    expect(container.read(aiControllerProvider).isConfigured, isTrue);
    final sending = controller.send('Hello');
    await Future<void>.delayed(Duration.zero);
    await controller.clear();
    delayed.reply.complete(const Ok('Late answer'));
    await sending;
    expect(container.read(aiControllerProvider).messages, isEmpty);
    expect(f.chat.messages, isEmpty);
    expect(container.read(aiControllerProvider).typing, isFalse);
  });
}
