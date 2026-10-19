import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/data/services/native_guard_service.dart';
import 'package:shakti/domain/entities/incident.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const method = MethodChannel('shakti/guard');
  const codec = StandardMethodCodec();

  late List<MethodCall> calls;
  String? launchTrigger;

  /// Emits [wires] as EventChannel events once Dart starts listening.
  void mockEvents(List<Object?> wires) {
    messenger.setMockMessageHandler('shakti/guard/events', (ByteData? msg) async {
      final call = codec.decodeMethodCall(msg);
      if (call.method == 'listen') {
        for (final w in wires) {
          await messenger.handlePlatformMessage(
            'shakti/guard/events',
            codec.encodeSuccessEnvelope(w),
            (_) {},
          );
        }
      }
      return codec.encodeSuccessEnvelope(null);
    });
  }

  setUp(() {
    calls = [];
    launchTrigger = null;
    messenger.setMockMethodCallHandler(method, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isAccessibilityEnabled':
          return true;
        case 'consumeLaunchTrigger':
          final t = launchTrigger;
          launchTrigger = null;
          return t;
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(method, null);
    messenger.setMockMessageHandler('shakti/guard/events', null);
  });

  test('method calls are forwarded with arguments', () async {
    final s = MethodChannelNativeGuardService();
    await s.startGuard();
    await s.setSecureScreen(false);
    await s.stopGuard();
    await s.openAccessibilitySettings();
    expect(await s.isAccessibilityEnabled(), isTrue);
    expect(calls.map((c) => c.method), [
      'startGuard',
      'setSecureScreen',
      'stopGuard',
      'openAccessibilitySettings',
      'isAccessibilityEnabled',
    ]);
    expect(calls[1].arguments, false);
  });

  test('streams known triggers, drops unknown values', () async {
    mockEvents(['TRIPLE_POWER', 'BOGUS', 42, 'VOLUME_TRIPLE']);
    final s = MethodChannelNativeGuardService();
    final got = <TriggerSource>[];
    final sub = s.triggers.listen(got.add);
    await pumpEventQueue();
    await sub.cancel();
    expect(got, [TriggerSource.triplePower, TriggerSource.volumeTriple]);
  });

  test('emits the launch trigger once on first subscription', () async {
    mockEvents([]);
    launchTrigger = 'TRIPLE_POWER';
    final s = MethodChannelNativeGuardService();
    final first = <TriggerSource>[];
    final sub = s.triggers.listen(first.add);
    await pumpEventQueue();
    await sub.cancel();
    expect(first, [TriggerSource.triplePower]);

    launchTrigger = 'VOLUME_TRIPLE';
    final second = <TriggerSource>[];
    final sub2 = s.triggers.listen(second.add);
    await pumpEventQueue();
    await sub2.cancel();
    expect(second, isEmpty);
    expect(calls.where((c) => c.method == 'consumeLaunchTrigger').length, 1);
  });

  test('is a no-op when no native side is registered', () async {
    messenger.setMockMethodCallHandler(method, null);
    final s = MethodChannelNativeGuardService();
    await s.startGuard();
    await s.setSecureScreen(true);
    expect(await s.isAccessibilityEnabled(), isFalse);
    final got = <TriggerSource>[];
    final sub = s.triggers.listen(got.add, onError: (_) => fail('should not error'));
    await pumpEventQueue();
    await sub.cancel();
    expect(got, isEmpty);
  });

  test('PlatformException is swallowed', () async {
    messenger.setMockMethodCallHandler(method, (call) async {
      throw PlatformException(code: 'X');
    });
    final s = MethodChannelNativeGuardService();
    await s.stopGuard();
    expect(await s.isAccessibilityEnabled(), isFalse);
  });
}
