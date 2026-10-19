/// Panic lifecycle state machine.
///
/// ```
///   idle ──trigger──▶ countdown ──activate──▶ active ──resolve──▶ resolved
///    ▲                   │                     ▲                     │
///    └──────abort────────┘                     │                     │
///   idle|resolved ─────triggerImmediate────────┘   (covert decoy PIN)│
///   resolved ──trigger / triggerImmediate── starts a new cycle ◀─────┘
/// ```
///
/// Every transition returns `true` when it was applied and `false` when it is
/// not legal from the current state, so callers can safely ignore duplicate
/// triggers (e.g. shake + power press firing at the same moment). The machine
/// holds no timers: the countdown length is owned by the caller.
library;

enum PanicMachineState { idle, countdown, active, resolved }

class PanicStateMachine {
  PanicMachineState _state = PanicMachineState.idle;

  PanicMachineState get state => _state;

  bool get _canStart => _state == PanicMachineState.idle || _state == PanicMachineState.resolved;

  /// idle | resolved -> countdown.
  bool trigger() => _move(_canStart, PanicMachineState.countdown);

  /// countdown -> idle (user cancelled a false alarm).
  bool abort() => _move(_state == PanicMachineState.countdown, PanicMachineState.idle);

  /// countdown -> active (countdown elapsed).
  bool activate() => _move(_state == PanicMachineState.countdown, PanicMachineState.active);

  /// idle | resolved -> active, skipping the countdown (covert decoy PIN).
  bool triggerImmediate() => _move(_canStart, PanicMachineState.active);

  /// active -> resolved.
  bool resolve() => _move(_state == PanicMachineState.active, PanicMachineState.resolved);

  /// Unconditionally returns to idle.
  void reset() => _state = PanicMachineState.idle;

  bool _move(bool allowed, PanicMachineState to) {
    if (!allowed) return false;
    _state = to;
    return true;
  }
}
