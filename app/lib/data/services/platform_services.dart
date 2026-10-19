import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:another_telephony/telephony.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/engines/voice_matcher.dart';
import '../../domain/services/services.dart';

class PlatformLocationService
    implements LocationService, CachedLocationService {
  @override
  LocationFix? cachedFix;
  LocationFix _remember(Position p) => cachedFix = LocationFix(
    point: GeoPoint(p.latitude, p.longitude),
    at: p.timestamp,
    speedKmh: p.speed * 3.6,
    accuracyM: p.accuracy,
  );
  Future<void> warmCache() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p != null) _remember(p);
    } catch (_) {}
  }

  @override
  Future<bool> ensurePermission({bool background = false}) async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (background && p == LocationPermission.whileInUse) {
      return Permission.locationAlways.request().isGranted;
    }
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  @override
  Future<Result<LocationFix>> currentFix({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      return Ok(
        _remember(
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: timeout,
            ),
          ).timeout(timeout),
        ),
      );
    } catch (e) {
      return cachedFix == null
          ? Err('Location unavailable', e)
          : Ok(cachedFix!);
    }
  }

  @override
  Stream<LocationFix> watch({
    Duration interval = const Duration(seconds: 10),
  }) => Geolocator.getPositionStream(
    locationSettings: AndroidSettings(
      accuracy: LocationAccuracy.high,
      intervalDuration: interval,
      distanceFilter: 0,
    ),
  ).map(_remember);
}

class PlatformSmsService implements SmsService {
  final Telephony _sms = Telephony.instance;
  Future<Result<int>>? _active;
  @override
  Future<bool> ensurePermission() => Permission.sms.request().isGranted;
  @override
  Future<Result<int>> sendToAll(List<String> phones, String message) {
    if (_active != null) return Future.value(const Err('Another SMS dispatch is still running'));
    return _active = _send(phones, message).whenComplete(() => _active = null);
  }
  Future<Result<int>> _send(List<String> phones, String message) async {
    if (!Platform.isAndroid || !await Permission.sms.isGranted) return const Err('SMS permission is required');
    var sent = 0;
    await Future.wait(phones.toSet().map((phone) async {
      try {
        // Callback API cannot correlate recipients. Successful invocation means
        // Android accepted the handoff, NOT confirmed carrier delivery.
        await _sms.sendSms(to: phone, message: message, isMultipart: true).timeout(const Duration(seconds: 5));
        sent++;
      } catch (_) {}
    }));
    return sent > 0 ? Ok(sent) : const Err('Android could not accept SMS. Check SIM, permission and service');
  }
}

class PlatformConnectivityService implements ConnectivityService {
  final _plugin = Connectivity();
  bool _online(List<ConnectivityResult> values) =>
      values.any((v) => v != ConnectivityResult.none);
  @override
  Future<bool> isOnline() async => _online(await _plugin.checkConnectivity());
  @override
  Stream<bool> get onlineChanges =>
      _plugin.onConnectivityChanged.map(_online).distinct();
}

class PlatformBatteryService implements BatteryService {
  @override
  Future<int?> level() async {
    try {
      return await Battery().batteryLevel;
    } catch (_) {
      return null;
    }
  }
}

class PlatformSecureStore implements SecureStore {
  const PlatformSecureStore();
  static const _store = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _store.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _store.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _store.delete(key: key);
}

class PlatformBiometricService implements BiometricService {
  final _auth = LocalAuthentication();
  @override
  Future<bool> get available async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

class PlatformHapticsService implements HapticsService {
  @override
  Future<void> tick() => Vibration.vibrate(duration: 40);
  @override
  Future<void> heavy() => Vibration.vibrate(duration: 180);
  @override
  Future<void> sosPattern() => Vibration.vibrate(
    pattern: [0, 100, 100, 100, 100, 100, 250, 300, 100, 300, 100, 300],
  );
  @override
  Future<void> cancel() => Vibration.cancel();
}

class PlatformShakeSensorService implements ShakeSensorService {
  @override
  Stream<({double x, double y, double z, DateTime at})> get samples =>
      accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
          .map((e) => (x: e.x, y: e.y, z: e.z, at: e.timestamp));
}

class PlatformVoiceTriggerService implements VoiceTriggerService {
  final _speech = SpeechToText();
  @override
  Future<bool> get available => _speech.initialize();
  @override
  bool get isListening => _speech.isListening;
  @override
  Future<void> start(List<String> phrases, void Function() onMatch) async {
    if (!await available) throw StateError('Speech recognition is unavailable');
    var matched = false;
    await _speech.listen(
      onResult: (r) {
        if (!matched && VoiceMatcher.matches(r.recognizedWords, phrases)) {
          matched = true;
          unawaited(stop());
          onMatch();
        }
      },
    );
  }

  @override
  Future<void> stop() => _speech.stop();
}

class PlatformStrobeService implements StrobeService {
  Timer? _timer;
  bool _on = false;
  bool _busy = false;
  @override
  Future<bool> get available => TorchLight.isTorchAvailable();
  @override
  Future<void> start({
    Duration period = const Duration(milliseconds: 120),
  }) async {
    await stop();
    if (!await available) throw StateError('Flashlight unavailable');
    _timer = Timer.periodic(period, (_) async {
      if (_busy) return;
      _busy = true;
      try {
        _on = !_on;
        if (_on) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (_) {
        _timer?.cancel();
      } finally {
        _busy = false;
      }
    });
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _on = false;
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }
}

class PlatformSirenService implements SirenService {
  final _player = AudioPlayer();
  bool _playing = false;
  @override
  bool get isPlaying => _playing;
  @override
  Future<void> start() async {
    // Locally synthesized PCM; no network or missing audio asset dependency.
    const rate = 22050, count = rate * 2;
    final bytes = ByteData(44 + count * 2);
    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + count * 2, Endian.little);
    ascii(8, 'WAVEfmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, count * 2, Endian.little);
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      phase += 2 * pi * (750 + 350 * sin(2 * pi * i / rate)) / rate;
      bytes.setInt16(44 + i * 2, (sin(phase) * 25000).round(), Endian.little);
    }
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(
      BytesSource(bytes.buffer.asUint8List(), mimeType: 'audio/wav'),
    );
    _playing = true;
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _playing = false;
  }

  Future<void> dispose() => _player.dispose();
}
