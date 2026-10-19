import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';

/// Invokes a Supabase edge function and returns its HTTP status and body.
/// Must not throw for HTTP errors; network errors may throw.
typedef FunctionsInvoker = Future<({int status, Object? data})> Function(
    String fn, Map<String, Object?> body);

/// Wraps `Supabase.instance.client.functions.invoke`, turning
/// [FunctionException] into a status code.
// coverage:ignore-start
FunctionsInvoker supabaseInvoker(SupabaseClient client) => (fn, body) async {
      try {
        final res = await client.functions.invoke(fn, body: body);
        return (status: res.status, data: res.data as Object?);
      } on FunctionException catch (e) {
        return (status: e.status, data: e.details as Object?);
      }
    };
// coverage:ignore-end

bool _is2xx(int s) => s >= 200 && s < 300;

/// AI guardian chat and FIR drafting through the `ai-guard` edge function.
class SupabaseAiService implements AiService {
  SupabaseAiService(this._invoke);
  final FunctionsInvoker _invoke;

  static const function = 'ai-guard';
  static const msgSignIn = 'Please sign in to use the AI guardian';
  static const msgRateLimited = 'Too many requests. Please wait a minute';
  static const msgUnavailable = 'The AI guardian is unavailable right now';

  static String errorFor(int status) => switch (status) {
        401 => msgSignIn,
        429 => msgRateLimited,
        _ => msgUnavailable,
      };

  @override
  Future<Result<String>> chat(List<ChatMessage> history, {GeoPoint? location}) => _call({
        'mode': 'chat',
        'messages': [
          for (final m in history)
            if (m.role == ChatRole.user || m.role == ChatRole.assistant) m.toApi(),
        ],
        if (location != null) 'location': {'lat': location.lat, 'lng': location.lng},
      });

  @override
  Future<Result<String>> draftFir(FirInput input) {
    final i = input.incident;
    return _call({
      'mode': 'fir',
      'messages': const <Object?>[],
      if (i.lat != null && i.lng != null) 'location': {'lat': i.lat, 'lng': i.lng},
      'fir': {
        'complainantName': input.complainantName,
        'narrative': input.narrative,
        'accusedDescription': input.accusedDescription,
        'incident': i.toRemoteJson(),
        'breadcrumbs': [for (final b in input.breadcrumbs.take(200)) b.toRemoteJson()],
      },
    });
  }

  Future<Result<String>> _call(Map<String, Object?> body) async {
    try {
      final res = await _invoke(function, body);
      if (!_is2xx(res.status)) return Err(errorFor(res.status));
      final data = res.data;
      final content = data is Map ? data['content'] : null;
      if (content is String && content.trim().isNotEmpty) return Ok(content.trim());
      return const Err(msgUnavailable);
    } catch (e) {
      return Err(msgUnavailable, e);
    }
  }
}

/// Telegram + push fan-out through the `emergency-dispatch` edge function.
class SupabaseCloudDispatchService implements CloudDispatchService {
  SupabaseCloudDispatchService(this._invoke);
  final FunctionsInvoker _invoke;

  static const function = 'emergency-dispatch';

  @override
  Future<Result<void>> dispatch(Incident incident, {required String userName, String? telegramChatId}) =>
      _send('sos', incident, userName, telegramChatId);

  @override
  Future<Result<void>> notifyResolved(Incident incident,
          {required String userName, String? telegramChatId}) =>
      _send('resolved', incident, userName, telegramChatId);

  Future<Result<void>> _send(String action, Incident incident, String userName, String? chatId) async {
    try {
      final res = await _invoke(function, {
        'action': action,
        'incident': incident.toRemoteJson(),
        'userName': userName,
        if (chatId != null && chatId.trim().isNotEmpty) 'telegramChatId': chatId.trim(),
      });
      if (_is2xx(res.status)) {
        final data = res.data;
        if (data is Map && ((data['telegram'] is num && (data['telegram'] as num) > 0) ||
            (data['push'] is num && (data['push'] as num) > 0))) {
          return const Ok(null);
        }
        return const Err('Incident saved, but no guardian alert was acknowledged. Check Telegram configuration');
      }
      return Err(switch (res.status) {
        401 => 'Not signed in to the cloud',
        429 => 'Cloud alert rate limited',
        _ => 'Cloud alert failed (${res.status})',
      });
    } catch (e) {
      return Err('Cloud alert failed', e);
    }
  }
}

/// Used when no backend is configured.
class OfflineAiService implements AiService {
  const OfflineAiService();
  static const message = 'AI guardian needs internet and a configured backend';

  @override
  Future<Result<String>> chat(List<ChatMessage> history, {GeoPoint? location}) async => const Err(message);

  @override
  Future<Result<String>> draftFir(FirInput input) async => const Err(message);
}

/// Used when no backend is configured.
class OfflineCloudDispatch implements CloudDispatchService {
  const OfflineCloudDispatch();
  static const message = 'Cloud alerts need a configured backend';

  @override
  Future<Result<void>> dispatch(Incident incident, {required String userName, String? telegramChatId}) async =>
      const Err(message);

  @override
  Future<Result<void>> notifyResolved(Incident incident,
          {required String userName, String? telegramChatId}) async =>
      const Err(message);
}
