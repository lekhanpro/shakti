import '../../../domain/entities/entities.dart';

enum PanicPhase { idle, countdown, active, resolved }

/// Immutable view state exposed by `panicControllerProvider`
/// (a `NotifierProvider` of `PanicController` in panic_controller.dart).
///
/// Controller API (consumed by UI and trigger sources):
/// ```dart
/// Future<void> trigger(TriggerSource source, {bool covert = false});
/// void abort();                               // only during countdown
/// Future<void> resolve({bool falseAlarm = false});
/// void acknowledge();                         // resolved to idle
/// ```
class PanicViewState {
  const PanicViewState({
    this.phase = PanicPhase.idle,
    this.secondsLeft = 0,
    this.totalSeconds = 5,
    this.source,
    this.report,
    this.covert = false,
    this.startedAt,
  });

  final PanicPhase phase;
  final int secondsLeft;
  final int totalSeconds;
  final TriggerSource? source;

  /// Live channel checklist once the incident is active.
  final DispatchReport? report;
  final bool covert;
  final DateTime? startedAt;

  Incident? get incident => report?.incident;

  PanicViewState copyWith({
    PanicPhase? phase,
    int? secondsLeft,
    int? totalSeconds,
    TriggerSource? source,
    DispatchReport? report,
    bool? covert,
    DateTime? startedAt,
  }) =>
      PanicViewState(
        phase: phase ?? this.phase,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        source: source ?? this.source,
        report: report ?? this.report,
        covert: covert ?? this.covert,
        startedAt: startedAt ?? this.startedAt,
      );
}
