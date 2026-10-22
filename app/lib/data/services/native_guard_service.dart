import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/incident.dart';
import '../../domain/services/services.dart';

/// Android implementation of [NativeGuardService] backed by the Kotlin layer
/// (MainActivity and GuardService).
///
/// Contract:
/// - MethodChannel `shakti/guard`: `startGuard`, `stopGuard`,
///   `setSecureScreen(bool)`, `consumeLaunchTrigger -> String?`.
/// - EventChannel `shakti/guard/events`: trigger wire strings
///   (`TRIPLE_POWER`), matching [TriggerSource.wire].
///
/// Every call swallows [MissingPluginException] / [PlatformException], so this
/// is a harmless no-op off Android and in tests.
class MethodChannelNativeGuardService implements NativeGuardService {
  MethodChannelNativeGuardService({
    MethodChannel methodChannel = const MethodChannel(methodChannelName),
    EventChannel eventChannel = const EventChannel(eventChannelName),
  })  : _method = methodChannel,
        _events = eventChannel;

  static const methodChannelName = 'shakti/guard';
  static const eventChannelName = 'shakti/guard/events';

  final MethodChannel _method;
  final EventChannel _events;

  Stream<TriggerSource>? _triggers;

  @override
  Stream<TriggerSource> get triggers => _triggers ??= _buildTriggers();

  Stream<TriggerSource> _buildTriggers() {
    late final StreamController<TriggerSource> controller;
    StreamSubscription<dynamic>? native;
    var launchChecked = false;

    void emitWire(Object? raw) {
      final source = _parse(raw);
      if (source != null && !controller.isClosed) controller.add(source);
    }

    controller = StreamController<TriggerSource>.broadcast(
      onListen: () {
        try {
          native = _events.receiveBroadcastStream().listen(
                emitWire,
                onError: (Object _) {}, // PlatformException from native: ignore
                cancelOnError: false,
              );
        } on MissingPluginException {
          native = null;
        } on PlatformException {
          native = null;
        }
        if (!launchChecked) {
          launchChecked = true;
          unawaited(_consumeLaunchTrigger().then(emitWire));
        }
      },
      onCancel: () async {
        final sub = native;
        native = null;
        try {
          await sub?.cancel();
        } on MissingPluginException {
          // no native side
        } on PlatformException {
          // ignore
        }
      },
    );
    return controller.stream;
  }

  /// Maps a wire string to a known native trigger; unknown values are dropped
  /// (fromWire would otherwise silently fall back to hudTap).
  static TriggerSource? _parse(Object? raw) {
    return raw == TriggerSource.triplePower.wire ? TriggerSource.triplePower : null;
  }

  Future<String?> _consumeLaunchTrigger() async {
    try {
      return await _method.invokeMethod<String>('consumeLaunchTrigger');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await _method.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> startGuard() => _invoke<void>('startGuard');

  @override
  Future<void> stopGuard() => _invoke<void>('stopGuard');

  @override
  Future<void> setSecureScreen(bool on) => _invoke<void>('setSecureScreen', on);
}
