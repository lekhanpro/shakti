import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/features/panic/application/panic_controller.dart';
import 'package:shakti/features/panic/application/panic_view_state.dart';
import 'package:shakti/features/panic/application/trigger_hub.dart';

import '../fakes/fakes.dart';

const g = 9.80665;

void main() {
  late Fakes f;
  late ProviderContainer c;

  Future<void> settle() async {
    await c.read(triggerHubProvider.notifier).settled;
    await Future<void>.delayed(Duration.zero);
    await c.read(triggerHubProvider.notifier).settled;
  }

  Future<void> start(SafetySettings s) async {
    f = Fakes();
    f.settings.settings = s;
    c = ProviderContainer(overrides: f.overrides());
    c.listen(panicControllerProvider, (_, _) {});
    c.read(triggerHubProvider);
    await settle();
  }

  tearDown(() => c.dispose());

  test('defaults arm native guard and shake, not voice', () async {
    await start(const SafetySettings());
    expect(f.nativeGuard.started, isTrue);
    expect(f.voice.starts, 0);
    expect(c.read(triggerHubProvider), const TriggerHubState(native: true, shake: true, voice: false));
  });

  test('a native power trigger starts the countdown', () async {
    await start(const SafetySettings());
    f.nativeGuard.fire(TriggerSource.triplePower);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final s = c.read(panicControllerProvider);
    expect(s.phase, PanicPhase.countdown);
    expect(s.source, TriggerSource.triplePower);
    c.read(panicControllerProvider.notifier).abort();
  });

  test('removed volume triggers are ignored even with legacy settings enabled', () async {
    await start(SafetySettings.fromJson({'powerTrigger': true, 'volumeTrigger': true}));
    f.nativeGuard.fire(TriggerSource.volumeTriple);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(panicControllerProvider).phase, PanicPhase.idle);
  });

  test('legacy volume settings cannot arm the native guard', () async {
    final settings = SafetySettings.fromJson({'powerTrigger': false, 'volumeTrigger': true});
    await start(settings);
    expect(f.nativeGuard.started, isFalse);
    expect(settings.toJson().containsKey('volumeTrigger'), isFalse);
  });

  test('violent shaking routes to a shake trigger', () async {
    await start(const SafetySettings(powerTrigger: false));
    final t0 = DateTime(2026, 9, 29, 22);
    for (var i = 0; i < 60; i++) {
      f.shake.emit(i.isEven ? 3.5 * g : -3.5 * g, 0, g, t0.add(Duration(milliseconds: i * 20)));
    }
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final s = c.read(panicControllerProvider);
    expect(s.phase, PanicPhase.countdown);
    expect(s.source, TriggerSource.shake);
    c.read(panicControllerProvider.notifier).abort();
  });

  test('voice keyword match routes to a voice trigger', () async {
    await start(const SafetySettings(voiceTrigger: true, voicePhrases: ['shakti help']));
    expect(f.voice.starts, 1);
    expect(f.voice.phrases, ['shakti help']);
    f.voice.fire();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(panicControllerProvider).source, TriggerSource.voiceKeyword);
    c.read(panicControllerProvider.notifier).abort();
  });

  test('resubscribes when settings change', () async {
    await start(const SafetySettings());
    f.settings.settings = const SafetySettings(powerTrigger: false, shakeTrigger: false, voiceTrigger: true);
    await settle();
    expect(f.nativeGuard.stopCalls, 1);
    expect(f.voice.starts, 1);
    expect(c.read(triggerHubProvider), const TriggerHubState(voice: true));

    // Shake is now unsubscribed: shaking does nothing.
    final t0 = DateTime(2026, 9, 29, 22);
    for (var i = 0; i < 60; i++) {
      f.shake.emit(i.isEven ? 3.5 * g : -3.5 * g, 0, g, t0.add(Duration(milliseconds: i * 20)));
    }
    f.nativeGuard.fire(TriggerSource.triplePower);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(panicControllerProvider).phase, PanicPhase.idle);

    // Changing the phrases restarts the listener.
    f.settings.settings = const SafetySettings(
        powerTrigger: false, shakeTrigger: false, voiceTrigger: true, voicePhrases: ['bachao']);
    await settle();
    expect(f.voice.stops, 1);
    expect(f.voice.starts, 2);
    expect(f.voice.phrases, ['bachao']);
  });

  test('dispose stops the voice listener and cancels streams', () async {
    await start(const SafetySettings(voiceTrigger: true));
    expect(f.voice.isListening, isTrue);
    c.dispose();
    await Future<void>.delayed(Duration.zero);
    expect(f.voice.isListening, isFalse);
    expect(f.nativeGuard.triggerController.hasListener, isFalse);
    expect(f.shake.controller.hasListener, isFalse);
    // Re-create so tearDown's dispose is harmless.
    c = ProviderContainer(overrides: Fakes().overrides());
  });
}
