import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/data/remote/supabase_functions.dart';
import 'package:shakti/domain/entities/entities.dart';

class Recorder {
  Recorder(this.status, [this.data]);
  int status;
  Object? data;
  Object? throwThis;
  final calls = <(String, Map<String, Object?>)>[];

  Future<({int status, Object? data})> call(String fn, Map<String, Object?> body) async {
    calls.add((fn, body));
    final t = throwThis;
    if (t != null) throw t;
    return (status: status, data: data);
  }
}

final _incident = Incident(
  id: 'i1',
  source: TriggerSource.shake,
  status: IncidentStatus.active,
  createdAt: DateTime.utc(2026, 9, 29, 10),
  shareToken: 'abcdefghijklmnopqrstuvwxyz',
  lat: 12.97,
  lng: 77.59,
);

void main() {
  final history = [
    ChatMessage(id: '0', role: ChatRole.system, content: 'sys', createdAt: DateTime(2026)),
    ChatMessage(id: '1', role: ChatRole.user, content: 'I feel followed', createdAt: DateTime(2026)),
    ChatMessage(id: '2', role: ChatRole.assistant, content: 'Stay in a lit area', createdAt: DateTime(2026)),
  ];

  group('SupabaseAiService', () {
    test('chat sends only user/assistant roles and location', () async {
      final r = Recorder(200, {'content': ' Go to the police station. '});
      final res = await SupabaseAiService(r.call).chat(history, location: const GeoPoint(12.9, 77.6));
      expect(res.valueOrNull, 'Go to the police station.');
      final (fn, body) = r.calls.single;
      expect(fn, 'ai-guard');
      expect(body['mode'], 'chat');
      expect(body['messages'], [
        {'role': 'user', 'content': 'I feel followed'},
        {'role': 'assistant', 'content': 'Stay in a lit area'},
      ]);
      expect(body['location'], {'lat': 12.9, 'lng': 77.6});
    });

    test('chat without location omits it', () async {
      final r = Recorder(200, {'content': 'ok'});
      await SupabaseAiService(r.call).chat(history);
      expect(r.calls.single.$2.containsKey('location'), isFalse);
    });

    test('long conversations send the latest 20 turns', () async {
      final r = Recorder(200, {'content': 'ok'});
      final conversation = List.generate(
        45,
        (i) => ChatMessage(
          id: '$i',
          role: i.isEven ? ChatRole.user : ChatRole.assistant,
          content: 'turn $i',
          createdAt: DateTime(2026),
        ),
      );
      await SupabaseAiService(r.call).chat(conversation);
      final sent = r.calls.single.$2['messages']! as List;
      expect(sent, hasLength(20));
      expect((sent.first as Map)['content'], 'turn 25');
      expect((sent.last as Map)['content'], 'turn 44');
    });

    test('oversize chat is rejected before a network request', () async {
      final r = Recorder(200, {'content': 'ok'});
      final res = await SupabaseAiService(r.call)
          .chat([ChatMessage(id: 'long', role: ChatRole.user, content: 'x' * 2001, createdAt: DateTime(2026))]);
      expect(res.isOk, isFalse);
      expect(r.calls, isEmpty);
    });

    test('a hanging request returns a retryable timeout error', () async {
      final waiting = Completer<({int status, Object? data})>();
      final service = SupabaseAiService((_, _) => waiting.future, timeout: const Duration(milliseconds: 1));
      final result = await service.chat(history);
      expect((result as Err).message, contains('took too long'));
      waiting.complete((status: 200, data: {'content': 'late'}));
    });

    test('maps HTTP errors to friendly messages', () async {
      Future<String?> msg(int status) async => switch (await SupabaseAiService(Recorder(status).call).chat(history)) {
        Err(:final message) => message,
        Ok() => null,
      };
      expect(await msg(401), 'Please sign in to use the AI guardian');
      expect(await msg(429), 'Too many requests. Please wait a minute');
      expect(await msg(500), 'The AI guardian is unavailable right now');
      expect(await msg(400), 'The AI guardian is unavailable right now');
      expect(await msg(503), SupabaseAiService.msgNotConfigured);
    });

    test('empty content, bad body and exceptions are unavailable', () async {
      expect((await SupabaseAiService(Recorder(200, {'content': ''}).call).chat(history)).isOk, isFalse);
      expect((await SupabaseAiService(Recorder(200, 'text').call).chat(history)).isOk, isFalse);
      final r = Recorder(200)..throwThis = Exception('socket');
      final res = await SupabaseAiService(r.call).chat(history);
      expect((res as Err).message, SupabaseAiService.msgUnavailable);
    });

    test('draftFir sends the server contract without tracker tokens or a full location trail', () async {
      final r = Recorder(200, {'content': 'FIR text'});
      final res = await SupabaseAiService(r.call).draftFir(
        FirInput(
          incident: _incident,
          breadcrumbs: [Breadcrumb(incidentId: 'i1', lat: 1, lng: 2, recordedAt: DateTime.utc(2026))],
          complainantName: 'Priya',
          narrative: 'Followed near the bus stop',
          accusedDescription: 'Tall, red shirt',
        ),
      );
      expect(res.valueOrNull, 'FIR text');
      final body = r.calls.single.$2;
      expect(body['mode'], 'fir');
      expect(body.containsKey('location'), isFalse);
      final fir = body['fir']! as Map;
      expect(fir['complainantName'], 'Priya');
      expect(fir['narrative'], 'Followed near the bus stop');
      expect(fir['accusedDescription'], 'Tall, red shirt');
      expect(fir['incidentTime'], '2026-09-29T10:00:00.000Z');
      expect(fir['triggerLabel'], 'Shake or fall');
      expect(fir['latitude'], 12.97);
      expect(fir['longitude'], 77.59);
      expect(fir['breadcrumbCount'], 1);
      expect(fir['trailStart'], '2026-01-01T00:00:00.000Z');
      expect(fir['trailEnd'], '2026-01-01T00:00:00.000Z');
      expect(fir['hasAudio'], isFalse);
      expect(fir.containsKey('incident'), isFalse);
      expect(fir.containsKey('breadcrumbs'), isFalse);
      expect(body.toString(), isNot(contains(_incident.shareToken)));
    });
  });

  group('SupabaseCloudDispatchService', () {
    test('dispatch sends sos with incident, name and chat id', () async {
      final r = Recorder(200, {'telegram': 1, 'push': 0});
      final res = await SupabaseCloudDispatchService(r.call)
          .dispatch(_incident, userName: 'Priya', telegramChatId: ' -100123 ');
      expect(res.isOk, isTrue);
      final (fn, body) = r.calls.single;
      expect(fn, 'emergency-dispatch');
      expect(body['action'], 'sos');
      expect(body['userName'], 'Priya');
      expect(body['telegramChatId'], '-100123');
      expect(body['incident'], _incident.toRemoteJson());
    });

    test('notifyResolved sends resolved and omits blank chat id', () async {
      final r = Recorder(200, {'telegram': 1, 'push': 0});
      final res = await SupabaseCloudDispatchService(r.call)
          .notifyResolved(_incident, userName: 'Priya', telegramChatId: '');
      expect(res.isOk, isTrue);
      expect(r.calls.single.$2['action'], 'resolved');
      expect(r.calls.single.$2.containsKey('telegramChatId'), isFalse);
    });

    test('zero delivered alerts or malformed success is not reported as success', () async {
      for (final data in [
        {'telegram': 0, 'push': 0},
        {'ok': true},
        null,
      ]) {
        final result = await SupabaseCloudDispatchService(Recorder(200, data).call).dispatch(_incident, userName: 'x');
        expect(result.isOk, isFalse);
      }
    });

    test('non-2xx and exceptions are Err', () async {
      for (final s in [401, 429, 500]) {
        expect((await SupabaseCloudDispatchService(Recorder(s).call).dispatch(_incident, userName: 'x')).isOk, isFalse);
      }
      final r = Recorder(200)..throwThis = Exception('offline');
      expect((await SupabaseCloudDispatchService(r.call).dispatch(_incident, userName: 'x')).isOk, isFalse);
    });
  });

  test('offline implementations always Err', () async {
    const ai = OfflineAiService();
    expect((await ai.chat(history) as Err).message, 'AI guardian needs internet and a configured backend');
    expect(
      (await ai.draftFir(FirInput(incident: _incident, breadcrumbs: const [], complainantName: '', narrative: '')))
          .isOk,
      isFalse,
    );
    const cloud = OfflineCloudDispatch();
    expect((await cloud.dispatch(_incident, userName: 'x')).isOk, isFalse);
    expect((await cloud.notifyResolved(_incident, userName: 'x')).isOk, isFalse);
  });
}
