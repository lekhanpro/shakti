/// "Walk With Me" dead-man timer.
///
/// The user starts a timer for the expected journey. Unless she checks in
/// (with her PIN) before the deadline, the next [EscortTimer.tick] reports
/// expiry once and the caller raises an SOS with `TriggerSource.timerExpired`.
///
/// The timer never schedules anything itself: time comes from an injected
/// [Clock] and the caller polls [tick] (e.g. once a second), which keeps it
/// deterministic under test and safe across app suspension.
library;

import '../services/services.dart';

enum EscortStatus { idle, running, checkedIn, expired }

class EscortTimer {
  EscortTimer(this._clock);

  final Clock _clock;
  EscortStatus _status = EscortStatus.idle;
  DateTime? _startedAt;
  DateTime? _deadline;
  DateTime? _stoppedAt;

  EscortStatus get status => _status;
  DateTime? get deadline => _deadline;

  /// Time left before expiry; zero when not running. Never negative.
  Duration get remaining {
    if (_status != EscortStatus.running || _deadline == null) return Duration.zero;
    final left = _deadline!.difference(_clock.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Fraction of the (possibly extended) journey elapsed, clamped to 0..1.
  double get progress {
    final start = _startedAt;
    final end = _deadline;
    if (start == null || end == null) return 0;
    if (_status == EscortStatus.expired) return 1;
    final total = end.difference(start).inMicroseconds;
    if (total <= 0) return 1;
    final at = _status == EscortStatus.running ? _clock.now() : (_stoppedAt ?? _clock.now());
    return (at.difference(start).inMicroseconds / total).clamp(0.0, 1.0);
  }

  void start(Duration d) {
    final now = _clock.now();
    _startedAt = now;
    _deadline = now.add(d);
    _stoppedAt = null;
    _status = EscortStatus.running;
  }

  /// Adds [d] to the deadline. Ignored unless running.
  void extend(Duration d) {
    if (_status != EscortStatus.running) return;
    _deadline = _deadline!.add(d);
  }

  /// Safe arrival. Ignored unless running (an expiry alert is never undone).
  void checkIn() {
    if (_status != EscortStatus.running) return;
    _stoppedAt = _clock.now();
    _status = EscortStatus.checkedIn;
  }

  void cancel() {
    _status = EscortStatus.idle;
    _startedAt = null;
    _deadline = null;
    _stoppedAt = null;
  }

  /// Returns true the first time expiry is detected, and marks it expired.
  bool tick() {
    if (_status != EscortStatus.running) return false;
    if (_clock.now().isBefore(_deadline!)) return false;
    _stoppedAt = _deadline;
    _status = EscortStatus.expired;
    return true;
  }
}
