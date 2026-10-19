import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shakti/data/services/platform_evidence.dart';
import 'package:shakti/domain/services/services.dart';

class Recorder extends Mock implements AudioRecorder {}
class Store implements SecureStore {
  final values = <String,String>{};
  @override Future<String?> read(String key) async => values[key];
  @override Future<void> write(String key, String value) async { values[key] = value; }
  @override Future<void> delete(String key) async { values.remove(key); }
}
void main() {
  late Directory dir;
  late Recorder recorder;
  late PlatformAudioEvidenceService evidence;
  setUpAll(() => registerFallbackValue(const RecordConfig()));
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('shakti-evidence-test-');
    recorder = Recorder();
    when(() => recorder.hasPermission()).thenAnswer((_) async => true);
    when(() => recorder.stop()).thenAnswer((_) async => null);
    when(() => recorder.start(any(), path: any(named: 'path'))).thenAnswer((call) async { await File(call.namedArguments[#path] as String).writeAsBytes([1,2,3,4,5]); });
    evidence = PlatformAudioEvidenceService(Store(), recorder: recorder, supportDirectory: () async => dir, tempDirectory: () async => dir);
  });
  tearDown(() async { await dir.delete(recursive: true); });
  test('encrypts recording, removes plaintext and restores authenticated bytes', () async {
    final result = await evidence.record('incident-1', duration: Duration.zero);
    expect(result.isOk, isTrue);
    expect(File('${dir.path}/evidence/incident-1.recording.m4a').existsSync(), isFalse);
    final encoded = jsonDecode(await File(result.valueOrNull!).readAsString()) as Map;
    expect(base64Decode(encoded['ciphertext'] as String), isNot([1,2,3,4,5]));
    final decrypted = await evidence.decryptToTemp(result.valueOrNull!);
    expect(await File(decrypted.valueOrNull!).readAsBytes(), [1,2,3,4,5]);
    expect((await evidence.list()).single.incidentId, 'incident-1');
  });
  test('rejects tampered ciphertext and paths outside evidence directory', () async {
    final recorded = await evidence.record('incident-2', duration: Duration.zero);
    final file = File(recorded.valueOrNull!);
    final encoded = jsonDecode(await file.readAsString()) as Map<String,dynamic>;
    encoded['ciphertext'] = base64Encode([9,9,9,9,9]);
    await file.writeAsString(jsonEncode(encoded));
    expect((await evidence.decryptToTemp(file.path)).isOk, isFalse);
    expect((await evidence.decryptToTemp('${dir.path}/outside.shakti')).isOk, isFalse);
    expect((await evidence.record('../escape', duration: Duration.zero)).isOk, isFalse);
  });
  test('denied microphone returns failure and does not invent evidence', () async {
    when(() => recorder.hasPermission()).thenAnswer((_) async => false);
    expect((await evidence.record('denied', duration: Duration.zero)).isOk, isFalse);
    expect(await evidence.list(), isEmpty);
    verifyNever(() => recorder.start(any(), path: any(named: 'path')));
  });
}
