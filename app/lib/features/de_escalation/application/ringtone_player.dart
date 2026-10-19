import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tiny seam over audioplayers so widget tests can fake the ringtone.
abstract interface class RingtonePlayer {
  Future<void> startLoop();
  Future<void> stop();
  Future<void> dispose();
}

class AudioRingtonePlayer implements RingtonePlayer {
  AudioPlayer? _player;

  @override
  Future<void> startLoop() async {
    try {
      final p = _player ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      await p.play(AssetSource('audio/ringtone.wav'), volume: 1);
    } catch (_) {
      // Missing asset or audio focus denied: the visual call still works.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  @override
  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}

/// A new player per call screen.
final ringtonePlayerProvider = Provider.autoDispose<RingtonePlayer>((ref) {
  final p = AudioRingtonePlayer();
  ref.onDispose(p.dispose);
  return p;
});
