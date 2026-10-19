import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/panic_state_machine.dart';

void main() {
  late PanicStateMachine m;
  setUp(() => m = PanicStateMachine());

  test('starts idle', () => expect(m.state, PanicMachineState.idle));

  test('trigger -> countdown -> activate -> resolve', () {
    expect(m.trigger(), isTrue);
    expect(m.state, PanicMachineState.countdown);
    expect(m.activate(), isTrue);
    expect(m.state, PanicMachineState.active);
    expect(m.resolve(), isTrue);
    expect(m.state, PanicMachineState.resolved);
  });

  test('second trigger during countdown or active is rejected', () {
    m.trigger();
    expect(m.trigger(), isFalse);
    expect(m.triggerImmediate(), isFalse);
    m.activate();
    expect(m.trigger(), isFalse);
    expect(m.triggerImmediate(), isFalse);
    expect(m.state, PanicMachineState.active);
  });

  test('abort only from countdown', () {
    expect(m.abort(), isFalse);
    m.trigger();
    expect(m.abort(), isTrue);
    expect(m.state, PanicMachineState.idle);
    m.triggerImmediate();
    expect(m.abort(), isFalse);
    expect(m.state, PanicMachineState.active);
  });

  test('activate only from countdown, resolve only from active', () {
    expect(m.activate(), isFalse);
    expect(m.resolve(), isFalse);
    m.trigger();
    expect(m.resolve(), isFalse);
    m.activate();
    expect(m.activate(), isFalse);
  });

  test('triggerImmediate goes straight to active (covert decoy)', () {
    expect(m.triggerImmediate(), isTrue);
    expect(m.state, PanicMachineState.active);
  });

  test('can re-trigger after resolved', () {
    m.triggerImmediate();
    m.resolve();
    expect(m.trigger(), isTrue);
    expect(m.state, PanicMachineState.countdown);
    m.activate();
    m.resolve();
    expect(m.triggerImmediate(), isTrue);
  });

  test('reset returns to idle from anywhere', () {
    m.triggerImmediate();
    m.reset();
    expect(m.state, PanicMachineState.idle);
  });
}
