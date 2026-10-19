import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/escort_timer.dart';
import 'package:shakti/domain/services/services.dart';

class FakeClock implements Clock {
  FakeClock(this.t);
  DateTime t;
  void advance(Duration d) => t = t.add(d);
  @override
  DateTime now() => t;
}

void main() {
  late FakeClock clock;
  late EscortTimer timer;

  setUp(() {
    clock = FakeClock(DateTime(2026, 9, 29, 21));
    timer = EscortTimer(clock);
  });

  test('idle by default', () {
    expect(timer.status, EscortStatus.idle);
    expect(timer.remaining, Duration.zero);
    expect(timer.progress, 0);
    expect(timer.deadline, isNull);
    expect(timer.tick(), isFalse);
  });

  test('start sets deadline and counts down', () {
    timer.start(const Duration(minutes: 10));
    expect(timer.status, EscortStatus.running);
    expect(timer.deadline, clock.t.add(const Duration(minutes: 10)));
    clock.advance(const Duration(minutes: 4));
    expect(timer.remaining, const Duration(minutes: 6));
    expect(timer.progress, closeTo(0.4, 1e-9));
    expect(timer.tick(), isFalse);
  });

  test('tick reports expiry exactly once', () {
    timer.start(const Duration(minutes: 1));
    clock.advance(const Duration(minutes: 2));
    expect(timer.remaining, Duration.zero, reason: 'never negative');
    expect(timer.progress, 1);
    expect(timer.tick(), isTrue);
    expect(timer.status, EscortStatus.expired);
    expect(timer.tick(), isFalse);
    expect(timer.progress, 1);
    expect(timer.remaining, Duration.zero);
  });

  test('expires at exactly the deadline', () {
    timer.start(const Duration(seconds: 30));
    clock.advance(const Duration(seconds: 30));
    expect(timer.tick(), isTrue);
  });

  test('extend pushes the deadline out', () {
    timer.start(const Duration(minutes: 5));
    clock.advance(const Duration(minutes: 4));
    timer.extend(const Duration(minutes: 5));
    expect(timer.remaining, const Duration(minutes: 6));
    expect(timer.progress, closeTo(0.4, 1e-9));
    clock.advance(const Duration(minutes: 5));
    expect(timer.tick(), isFalse);
    clock.advance(const Duration(minutes: 1));
    expect(timer.tick(), isTrue);
  });

  test('extend is ignored unless running', () {
    timer.extend(const Duration(minutes: 5));
    expect(timer.status, EscortStatus.idle);
    expect(timer.deadline, isNull);
  });

  test('checkIn stops the timer and prevents expiry', () {
    timer.start(const Duration(minutes: 10));
    clock.advance(const Duration(minutes: 5));
    timer.checkIn();
    expect(timer.status, EscortStatus.checkedIn);
    expect(timer.progress, closeTo(0.5, 1e-9));
    expect(timer.remaining, Duration.zero);
    clock.advance(const Duration(hours: 1));
    expect(timer.tick(), isFalse);
    expect(timer.status, EscortStatus.checkedIn);
  });

  test('checkIn after expiry does not undo the alert', () {
    timer.start(const Duration(minutes: 1));
    clock.advance(const Duration(minutes: 2));
    timer.tick();
    timer.checkIn();
    expect(timer.status, EscortStatus.expired);
  });

  test('cancel returns to idle', () {
    timer.start(const Duration(minutes: 10));
    timer.cancel();
    expect(timer.status, EscortStatus.idle);
    expect(timer.deadline, isNull);
    clock.advance(const Duration(hours: 1));
    expect(timer.tick(), isFalse);
  });

  test('start can restart after check-in', () {
    timer.start(const Duration(minutes: 1));
    timer.checkIn();
    timer.start(const Duration(minutes: 2));
    expect(timer.status, EscortStatus.running);
    expect(timer.remaining, const Duration(minutes: 2));
  });

  test('zero-length start expires immediately', () {
    timer.start(Duration.zero);
    expect(timer.progress, 1);
    expect(timer.tick(), isTrue);
  });
}
