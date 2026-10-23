import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../../../domain/engines/distress_classifier.dart';
import '../../../domain/entities/entities.dart';

/// Short, practical tips shown when the assistant cannot be reached.
const offlineSafetyTips = [
  'If you feel followed, walk into a shop, pharmacy or police station and stay near staff.',
  'Call 112 for any emergency. 181 is the women helpline and 1091 the women police line.',
  'Share your live location with a trusted contact before a late journey.',
  'Keep to lit, busy roads. Cross the street and change pace to test if someone is following.',
  'Say "No" firmly and loudly. Drawing attention from bystanders often ends harassment.',
];

class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.loaded = false,
    this.typing = false,
    this.isConfigured = false,
    this.locationEnabled = false,
    this.error,
    this.distress = DistressLevel.none,
    this.crisisDismissed = false,
  });

  final List<ChatMessage> messages;
  final bool loaded;
  final bool typing;
  final bool isConfigured;
  final bool locationEnabled;

  /// Last send failure; the UI shows retry plus [offlineSafetyTips].
  final String? error;

  /// Highest distress level seen in the latest user message.
  final DistressLevel distress;
  final bool crisisDismissed;

  bool get showCrisis => distress == DistressLevel.danger && !crisisDismissed;
  bool get showConcern => distress == DistressLevel.concern && !crisisDismissed;

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? loaded,
    bool? typing,
    bool? isConfigured,
    bool? locationEnabled,
    String? error,
    bool clearError = false,
    DistressLevel? distress,
    bool? crisisDismissed,
  }) => AiChatState(
    messages: messages ?? this.messages,
    loaded: loaded ?? this.loaded,
    typing: typing ?? this.typing,
    isConfigured: isConfigured ?? this.isConfigured,
    locationEnabled: locationEnabled ?? this.locationEnabled,
    error: clearError ? null : (error ?? this.error),
    distress: distress ?? this.distress,
    crisisDismissed: crisisDismissed ?? this.crisisDismissed,
  );
}

class AiController extends Notifier<AiChatState> {
  static const _uuid = Uuid();
  StreamSubscription<List<ChatMessage>>? _sub;
  int _request = 0;
  static const maxMessageChars = 2000;

  @override
  AiChatState build() {
    _sub = ref
        .read(chatRepositoryProvider)
        .watchAll()
        .listen(
          (list) => state = state.copyWith(messages: list, loaded: true),
          onError: (_) => state = state.copyWith(loaded: true),
        );
    ref.onDispose(() => _sub?.cancel());
    return AiChatState(isConfigured: ref.watch(aiBackendConfiguredProvider));
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || state.typing) return;
    if (text.length > maxMessageChars) {
      state = state.copyWith(error: 'Please keep each message within 2,000 characters');
      return;
    }

    final level = DistressClassifier.classify(text);
    final pendingRequest = _request;
    state = state.copyWith(typing: true, distress: level, crisisDismissed: false, clearError: true);

    final msg = ChatMessage(
      id: _uuid.v4(),
      role: ChatRole.user,
      content: text,
      createdAt: ref.read(clockProvider).now(),
    );
    final repo = ref.read(chatRepositoryProvider);
    try {
      await repo.add(msg);
    } catch (_) {
      // Storage failure should not block getting help.
    }
    if (!ref.mounted || pendingRequest != _request) return;
    final history = [...state.messages.where((m) => m.id != msg.id), msg];
    state = state.copyWith(messages: history);
    await _ask(history);
  }

  /// Re-asks the assistant with the current history after a failure.
  Future<void> retry() async {
    if (state.typing || state.messages.isEmpty || state.messages.last.role != ChatRole.user) {
      return;
    }
    await _ask(state.messages);
  }

  Future<void> _ask(List<ChatMessage> history) async {
    final request = ++_request;
    state = state.copyWith(typing: true, clearError: true);
    GeoPoint? at;
    if (state.locationEnabled) {
      try {
        final fix = await ref.read(locationServiceProvider).currentFix(timeout: const Duration(seconds: 2));
        final point = fix.valueOrNull?.point;
        // Chat needs a neighbourhood, not a precise location trail.
        if (point != null) {
          at = GeoPoint((point.lat * 100).round() / 100, (point.lng * 100).round() / 100);
        }
      } catch (_) {}
    }
    if (!ref.mounted || request != _request) return;
    if (!state.locationEnabled) at = null;

    Result<String> res;
    try {
      res = await ref.read(aiServiceProvider).chat(history, location: at);
    } catch (e) {
      res = Err('AI unavailable', e);
    }
    if (!ref.mounted || request != _request) return;

    switch (res) {
      case Ok(:final value):
        final reply = ChatMessage(
          id: _uuid.v4(),
          role: ChatRole.assistant,
          content: value,
          createdAt: ref.read(clockProvider).now(),
        );
        try {
          await ref.read(chatRepositoryProvider).add(reply);
        } catch (_) {}
        if (!ref.mounted || request != _request) return;
        final msgs = state.messages.any((m) => m.id == reply.id) ? state.messages : [...state.messages, reply];
        state = state.copyWith(typing: false, messages: msgs);
      case Err(:final message):
        state = state.copyWith(typing: false, error: message);
    }
  }

  void dismissCrisis() => state = state.copyWith(crisisDismissed: true);

  /// Applies to future requests only; previously sent context cannot be recalled.
  void setLocationEnabled(bool enabled) => state = state.copyWith(locationEnabled: enabled);

  Future<void> clear() async {
    ++_request;
    try {
      await ref.read(chatRepositoryProvider).clear();
    } catch (_) {}
    if (!ref.mounted) return;
    state = state.copyWith(messages: const [], typing: false, distress: DistressLevel.none, clearError: true);
  }
}

final aiControllerProvider = NotifierProvider<AiController, AiChatState>(AiController.new);
