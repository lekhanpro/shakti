import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/engines/shake_filter.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/services.dart';
import 'panic_controller.dart';

/// Which hands-free trigger sources are currently armed.
class TriggerHubState {
  const TriggerHubState({this.native = false, this.shake = false, this.voice = false});

  final bool native;
  final bool shake;
  final bool voice;

  bool get any => native || shake || voice;

  @override
  bool operator ==(Object other) =>
      other is TriggerHubState && other.native == native && other.shake == shake && other.voice == voice;

  @override
  int get hashCode => Object.hash(native, shake, voice);
}

/// Arms native (power / volume), shake and voice triggers according to the
/// live settings and routes each one to [PanicController.trigger].
///
/// Re-subscribes whenever the relevant settings change; everything is torn
/// down on dispose. Duplicate triggers are harmless: the panic state machine
/// ignores a trigger while an incident is already running.
class TriggerHub extends Notifier<TriggerHubState> {
  StreamSubscription<SafetySettings>? _settingsSub;
  StreamSubscription<TriggerSource>? _nativeSub;
  StreamSubscription<({double x, double y, double z, DateTime at})>? _shakeSub;
  ShakeFilter? _shakeFilter;
  bool _voiceOn = false;
  VoiceTriggerService? _voiceService;
  List<String> _phrases = const [];
  SafetySettings _lastSettings = const SafetySettings();

  /// Serialises apply() calls so rapid settings changes never interleave.
  Future<void> _chain = Future.value();

  @override
  TriggerHubState build() {
    ref.onDispose(_dispose);
    _settingsSub = ref.read(settingsRepositoryProvider).watch().listen(
          (s) => _chain = _chain.then((_) => _apply(s)).catchError((Object _) {}),
          onError: (Object _) {},
        );
    // Also apply the current value, in case watch() doesn't replay it.
    _chain = ref
        .read(settingsRepositoryProvider)
        .load()
        .then(_apply)
        .catchError((Object _) {});
    return const TriggerHubState();
  }

  /// Completes once every settings change seen so far has been applied.
  Future<void> get settled => _chain;

  void _fire(TriggerSource source) {
    if (!ref.mounted) return;
    unawaited(ref.read(panicControllerProvider.notifier).trigger(source));
  }

  Future<void> _apply(SafetySettings s) async {
    if (!ref.mounted) return;
    _lastSettings = s;
    final wantNative = s.powerTrigger || s.volumeTrigger;
    final wantShake = s.shakeTrigger;
    final wantVoice = s.voiceTrigger && s.voicePhrases.isNotEmpty;

    // Native guard (power button / volume keys via the Kotlin service).
    if (wantNative && _nativeSub == null) {
      final guard = ref.read(nativeGuardServiceProvider);
      _nativeSub = guard.triggers.listen((source) {
        if (source == TriggerSource.triplePower && !_lastSettings.powerTrigger) return;
        if (source == TriggerSource.volumeTriple && !_lastSettings.volumeTrigger) return;
        _fire(source);
      }, onError: (Object _) {});
      await _safe(guard.startGuard);
    } else if (!wantNative && _nativeSub != null) {
      await _nativeSub?.cancel();
      _nativeSub = null;
      await _safe(ref.read(nativeGuardServiceProvider).stopGuard);
    }

    // Shake / fall.
    if (wantShake && _shakeSub == null) {
      _shakeFilter = ShakeFilter();
      _shakeSub = ref.read(shakeSensorServiceProvider).samples.listen((e) {
        if (_shakeFilter?.push(e.x, e.y, e.z, e.at) ?? false) _fire(TriggerSource.shake);
      }, onError: (Object _) {});
    } else if (!wantShake && _shakeSub != null) {
      await _shakeSub?.cancel();
      _shakeSub = null;
      _shakeFilter = null;
    }

    // Voice keyword. Restart when the phrase list changes.
    final voice = ref.read(voiceTriggerServiceProvider);
    _voiceService = voice;
    final phrasesChanged = !_sameList(_phrases, s.voicePhrases);
    if (wantVoice && (!_voiceOn || phrasesChanged)) {
      if (_voiceOn) await _safe(voice.stop);
      _phrases = List.unmodifiable(s.voicePhrases);
      final ok = await _safe(() => voice.start(_phrases, () => _fire(TriggerSource.voiceKeyword)));
      _voiceOn = ok;
    } else if (!wantVoice && _voiceOn) {
      await _safe(voice.stop);
      _voiceOn = false;
    }

    if (!ref.mounted) return;
    state = TriggerHubState(native: _nativeSub != null, shake: _shakeSub != null, voice: _voiceOn);
  }

  void _dispose() {
    _settingsSub?.cancel();
    _nativeSub?.cancel();
    _shakeSub?.cancel();
    // No ref access here: ref is unusable inside onDispose. Use the
    // service instance captured during _apply.
    final voice = _voiceService;
    if (_voiceOn && voice != null) {
      unawaited(_safe(voice.stop));
    }
    _voiceOn = false;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Future<bool> _safe(Future<void> Function() f) async {
    try {
      await f();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final triggerHubProvider = NotifierProvider<TriggerHub, TriggerHubState>(TriggerHub.new);
