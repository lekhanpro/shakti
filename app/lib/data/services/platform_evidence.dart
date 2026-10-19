import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';

class PlatformAudioEvidenceService implements AudioEvidenceService {
  PlatformAudioEvidenceService(
    this._store, {
    AudioRecorder? recorder,
    Future<Directory> Function()? supportDirectory,
    Future<Directory> Function()? tempDirectory,
  }) : _recorder = recorder ?? AudioRecorder(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;
  final Future<Directory> Function() _supportDirectory;
  final Future<Directory> Function() _tempDirectory;
  final SecureStore _store;
  final AudioRecorder _recorder;
  final _cipher = AesGcm.with256bits();
  Completer<void>? _stopSignal;
  Future<Result<String>>? _recording;
  Future<SecretKey>? _keyInFlight;
  Future<SecretKey> _key() =>
      _keyInFlight ??= _loadKey().whenComplete(() => _keyInFlight = null);
  Future<SecretKey> _loadKey() async {
    final encoded = await _store.read('evidence.aes256.v1');
    if (encoded != null) return SecretKey(base64Decode(encoded));
    final key = await _cipher.newSecretKey();
    await _store.write(
      'evidence.aes256.v1',
      base64Encode(await key.extractBytes()),
    );
    return key;
  }

  Future<Directory> _directory() async =>
      Directory(p.join((await _supportDirectory()).path, 'evidence'))
          .create(recursive: true);
  Future<File> _owned(String path) async {
    final root = p.normalize(p.absolute((await _directory()).path));
    final file = p.normalize(p.absolute(path));
    if (!p.isWithin(root, file) || !file.endsWith('.shakti')) {
      throw ArgumentError('Invalid evidence file');
    }
    return File(file);
  }

  @override
  Future<Result<String>> record(
    String incidentId, {
    Duration duration = const Duration(seconds: 60),
  }) {
    if (_recording != null) {
      return Future.value(const Err('An evidence recording is already active'));
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(incidentId)) {
      return Future.value(const Err('Invalid incident identifier'));
    }
    return _recording = _record(
      incidentId,
      duration,
    ).whenComplete(() => _recording = null);
  }

  Future<Result<String>> _record(String id, Duration duration) async {
    File? raw;
    final stopped = Completer<void>();
    _stopSignal = stopped;
    try {
      if (!await _recorder.hasPermission()) {
        return const Err('Microphone permission is required');
      }
      final key = await _key();
      final dir = await _directory();
      raw = File(p.join(dir.path, '$id.recording.m4a'));
      final started = DateTime.now().toUtc();
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: raw.path,
      );
      await Future.any([Future<void>.delayed(duration), stopped.future]);
      await _recorder.stop();
      final box = await _cipher.encrypt(
        await raw.readAsBytes(),
        secretKey: key,
      );
      final output = File(p.join(dir.path, '$id.shakti'));
      final pending = File('${output.path}.pending');
      await pending.writeAsString(
        jsonEncode({
          'version': 1,
          'incidentId': id,
          'createdAt': started.toIso8601String(),
          'nonce': base64Encode(box.nonce),
          'mac': base64Encode(box.mac.bytes),
          'ciphertext': base64Encode(box.cipherText),
        }),
        flush: true,
      );
      await pending.rename(output.path);
      return Ok(output.path);
    } catch (e) {
      return Err('Evidence recording could not be saved', e);
    } finally {
      try {
        await _recorder.stop();
      } catch (_) {}
      if (raw != null && await raw.exists()) await raw.delete();
      if (identical(_stopSignal, stopped)) _stopSignal = null;
    }
  }

  @override
  Future<void> stop() async {
    final signal = _stopSignal;
    if (signal != null && !signal.isCompleted) signal.complete();
  }

  @override
  Future<List<EvidenceItem>> list() async {
    final result = <EvidenceItem>[];
    await for (final f in (await _directory()).list()) {
      if (f is! File || !f.path.endsWith('.shakti')) continue;
      try {
        final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
        result.add(
          EvidenceItem(
            path: f.path,
            incidentId: data['incidentId'] as String,
            createdAt: DateTime.parse(data['createdAt'] as String),
            sizeBytes: await f.length(),
          ),
        );
      } catch (_) {}
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Result<String>> decryptToTemp(String encryptedPath) async {
    try {
      final data = jsonDecode(
        await (await _owned(encryptedPath)).readAsString(),
      ) as Map<String, dynamic>;
      if (data['version'] != 1) {
        return const Err('Unsupported evidence version');
      }
      final bytes = await _cipher.decrypt(
        SecretBox(
          base64Decode(data['ciphertext'] as String),
          nonce: base64Decode(data['nonce'] as String),
          mac: Mac(base64Decode(data['mac'] as String)),
        ),
        secretKey: await _key(),
      );
      final dir = await Directory(
        p.join((await _tempDirectory()).path, 'shakti-export'),
      ).create(recursive: true);
      final output = File(
        p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}.m4a'),
      );
      await output.writeAsBytes(bytes, flush: true);
      return Ok(output.path);
    } catch (e) {
      return Err('Evidence cannot be decrypted or failed authentication', e);
    }
  }

  @override
  Future<void> delete(String encryptedPath) async {
    final f = await _owned(encryptedPath);
    if (await f.exists()) await f.delete();
  }

  Future<void> cleanInterruptedFiles() async {
    await for (final f in (await _directory()).list()) {
      if (f is File &&
          (f.path.endsWith('.recording.m4a') || f.path.endsWith('.pending'))) {
        await f.delete();
      }
    }
    final dir = Directory(
      p.join((await _tempDirectory()).path, 'shakti-export'),
    );
    if (await dir.exists()) {
      await for (final f in dir.list()) {
        if (f is File) await f.delete();
      }
    }
  }
}

class PlatformEvidenceExportService implements EvidenceExportService {
  PlatformEvidenceExportService(this._evidence);
  final AudioEvidenceService _evidence;
  @override
  Future<Result<void>> share(String encryptedPath) async {
    final decrypted = await _evidence.decryptToTemp(encryptedPath);
    if (decrypted case Err<String>(:final message)) return Err(message);
    final file = File(decrypted.valueOrNull!);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'audio/mp4')],
          subject: 'Shakti incident evidence',
        ),
      );
      if (result.status == ShareResultStatus.unavailable) {
        return const Err('Sharing is unavailable');
      }
      return const Ok(null);
    } catch (e) {
      return Err('Could not share evidence', e);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }
}
