import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/engines/escort_timer.dart';
import '../../../domain/engines/pin_hasher.dart';
import '../../../domain/engines/proximity.dart';
import '../../../domain/entities/entities.dart';
import '../../panic/application/panic_controller.dart';

/// Secure-store key holding the PBKDF2 PIN hash (written by onboarding).
const pinHashKey = 'pin_hash';

/// Warning fires this long before expiry.
const escortWarnBefore = Duration(minutes: 2);

class EscortState {
  const EscortState({
    this.status = EscortStatus.idle,
    this.remaining = Duration.zero,
    this.progress = 0,
    this.total = Duration.zero,
    this.destination,
    this.warned = false,
    this.arrivedAt,
    this.arrivalHandled = false,
    this.notifiedContacts = 0,
  });

  final EscortStatus status;
  final Duration remaining;
  final double progress;

  /// Planned journey length including extensions.
  final Duration total;
  final SafePlace? destination;

  /// True once the two-minute warning has fired for this run.
  final bool warned;

  /// Safe place the user entered while the escort was running.
  final SafePlace? arrivedAt;

  /// True once the arrival prompt was answered (ask once).
  final bool arrivalHandled;
  final int notifiedContacts;

  bool get running => status == EscortStatus.running;

  EscortState copyWith({
    EscortStatus? status,
    Duration? remaining,
    double? progress,
    Duration? total,
    SafePlace? destination,
    bool clearDestination = false,
    bool? warned,
    SafePlace? arrivedAt,
    bool clearArrival = false,
    bool? arrivalHandled,
    int? notifiedContacts,
  }) =>
      EscortState(
        status: status ?? this.status,
        remaining: remaining ?? this.remaining,
        progress: progress ?? this.progress,
        total: total ?? this.total,
        destination: clearDestination ? null : (destination ?? this.destination),
        warned: warned ?? this.warned,
        arrivedAt: clearArrival ? null : (arrivedAt ?? this.arrivedAt),
        arrivalHandled: arrivalHandled ?? this.arrivalHandled,
        notifiedContacts: notifiedContacts ?? this.notifiedContacts,
      );
}

/// "Walk with me" dead-man timer. Polls [EscortTimer] once a second, warns two
/// minutes before the deadline, raises an SOS on expiry, and watches location
/// for arrival at a user-defined safe place.
class EscortController extends Notifier<EscortState> {
  EscortTimer? _timer;
  Timer? _ticker;
  StreamSubscription<LocationFix>? _geo;
  List<SafePlace> _places = const [];

  /// Injectable for tests: the ticker period.
  static Duration tickEvery = const Duration(seconds: 1);

  @override
  EscortState build() {
    ref.onDispose(_stopWatchers);
    return const EscortState();
  }

  EscortTimer get _t => _timer ??= EscortTimer(ref.read(clockProvider));

  Future<void> start(Duration duration, {SafePlace? destination}) async {
    if (state.running) return;
    _t.start(duration);
    state = EscortState(
      status: EscortStatus.running,
      remaining: _t.remaining,
      progress: 0,
      total: duration,
      destination: destination,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(tickEvery, (_) => tick());
    await _watchArrival();
  }

  /// Advances the timer. Public so tests can drive it with a fake clock.
  void tick() {
    final t = _timer;
    if (t == null || !ref.mounted) return;
    if (t.tick()) {
      _stopWatchers();
      state = state.copyWith(status: EscortStatus.expired, remaining: Duration.zero, progress: 1);
      unawaited(ref.read(panicControllerProvider.notifier).trigger(TriggerSource.timerExpired));
      return;
    }
    if (t.status != EscortStatus.running) return;
    final left = t.remaining;
    var warned = state.warned;
    if (!warned && left <= escortWarnBefore) {
      warned = true;
      unawaited(_safe(() => ref.read(hapticsServiceProvider).heavy()));
    }
    state = state.copyWith(remaining: left, progress: t.progress, warned: warned);
  }

  void extend([Duration d = const Duration(minutes: 5)]) {
    if (!state.running) return;
    _t.extend(d);
    final left = _t.remaining;
    state = state.copyWith(
      total: state.total + d,
      remaining: left,
      progress: _t.progress,
      // Re-arm the warning when the extension moves us back out of the window.
      warned: left <= escortWarnBefore ? state.warned : false,
    );
  }

  /// Returns false (and keeps running) when [pin] does not match the stored
  /// hash. A missing hash never unlocks: the PIN is mandatory.
  Future<bool> checkIn(String pin) async {
    if (!state.running) return false;
    final hash = await _safe(() => ref.read(secureStoreProvider).read(pinHashKey));
    if (hash == null || hash.isEmpty) return false;
    final ok = await PinHasher.verify(pin, hash);
    if (!ok || !ref.mounted) return false;
    _finish();
    return true;
  }

  /// Ends the walk without a PIN from the running screen only after the user
  /// verified; the UI routes "End" through [checkIn].
  void reset() {
    _stopWatchers();
    _timer?.cancel();
    state = const EscortState();
  }

  /// Answer to the arrival prompt. When [checkIn] is true the walk ends and
  /// contacts are told by SMS. Either way the prompt is not shown again.
  Future<bool> answerArrival({required bool checkIn, String? pin}) async {
    final place = state.arrivedAt;
    if (!checkIn) {
      state = state.copyWith(arrivalHandled: true);
      return true;
    }
    if (place == null || pin == null || !await this.checkIn(pin)) return false;
    state = state.copyWith(arrivalHandled: true);
    final contacts = await _safe(() => ref.read(contactRepositoryProvider).active()) ?? const [];
    if (contacts.isEmpty) return true;
    final res = await _safe(
      () => ref.read(smsServiceProvider).sendToAll(
            [for (final c in contacts) c.phone],
            'I reached ${place.name} safely. - Shakti',
          ),
    );
    if (!ref.mounted) return true;
    state = state.copyWith(notifiedContacts: res?.valueOrNull ?? 0);
    return true;
  }

  /// Location update handler. Public for tests.
  void onFix(LocationFix fix) {
    if (!state.running || state.arrivedAt != null || state.arrivalHandled) return;
    final candidates = [
      ?state.destination,
      ..._places.where((p) => p.id != state.destination?.id),
    ];
    for (final p in candidates) {
      if (Proximity.within(fix.point, p.point, p.radiusM)) {
        state = state.copyWith(arrivedAt: p);
        unawaited(_safe(() => ref.read(hapticsServiceProvider).tick()));
        return;
      }
    }
  }

  void _finish() {
    _t.checkIn();
    _stopWatchers();
    state = state.copyWith(status: EscortStatus.checkedIn, progress: _t.progress);
  }

  Future<void> _watchArrival() async {
    _places = await _safe(() => ref.read(safePlaceRepositoryProvider).all()) ?? const [];
    if (!ref.mounted || !state.running) return;
    await _geo?.cancel();
    try {
      _geo = ref.read(locationServiceProvider).watch().listen(onFix, onError: (_) {});
    } catch (_) {
      // Location unavailable: the timer still protects the walk.
    }
  }

  void _stopWatchers() {
    _ticker?.cancel();
    _ticker = null;
    unawaited(_geo?.cancel());
    _geo = null;
  }

  Future<T?> _safe<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (_) {
      return null;
    }
  }
}

final escortControllerProvider = NotifierProvider<EscortController, EscortState>(EscortController.new);
