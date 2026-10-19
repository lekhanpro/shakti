import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/shake_filter.dart';

const g = 9.80665;
const dtMs = 20; // 50 Hz

/// Feeds [n] samples produced by [sample] (index -> x,y,z in m/s^2) starting
/// at [start]. Returns the indices where the filter fired.
List<int> feed(
  ShakeFilter f,
  DateTime start,
  int n,
  (double, double, double) Function(int i) sample,
) {
  final fired = <int>[];
  for (var i = 0; i < n; i++) {
    final (x, y, z) = sample(i);
    if (f.push(x, y, z, start.add(Duration(milliseconds: i * dtMs)))) fired.add(i);
  }
  return fired;
}

void main() {
  final t0 = DateTime(2026, 9, 29, 22);

  (double, double, double) rest(int _) => (0, 0, g);
  (double, double, double) violent(int i) => (i.isEven ? 3.5 * g : -3.5 * g, 0, g);

  test('violent shake (+-3.5 g at 50 Hz) triggers', () {
    final f = ShakeFilter();
    expect(feed(f, t0, 50, rest), isEmpty);
    final fired = feed(f, t0.add(const Duration(seconds: 1)), 25, violent);
    expect(fired, isNotEmpty);
    // Needs a few crossings, so it cannot fire on the very first sample.
    expect(fired.first, greaterThanOrEqualTo(2));
    expect(fired.first, lessThan(10));
  });

  test('walking (+-0.4 g, ~2 Hz) does not trigger', () {
    final f = ShakeFilter();
    final fired = feed(f, t0, 500, (i) {
      final phase = 2 * pi * 2 * i * dtMs / 1000;
      return (0.2 * g * cos(phase), 0.1 * g * sin(phase), g + 0.4 * g * sin(phase));
    });
    expect(fired, isEmpty);
  });

  test('fast jittery walking (+-0.4 g every sample) does not trigger', () {
    final f = ShakeFilter();
    final fired = feed(f, t0, 200, (i) => (i.isEven ? 0.4 * g : -0.4 * g, 0, g));
    expect(fired, isEmpty);
  });

  test('single drop spike (free fall, impact, rest) does not trigger', () {
    final f = ShakeFilter();
    feed(f, t0, 50, rest);
    final fired = feed(f, t0.add(const Duration(seconds: 1)), 100, (i) {
      if (i < 15) return (0.0, 0.0, 0.0); // ~300 ms free fall
      if (i == 15) return (0.5 * g, 0.3 * g, 6 * g); // impact
      return rest(i);
    });
    expect(fired, isEmpty);
  });

  test('debounce blocks a second trigger within 3 s, allows it after', () {
    final f = ShakeFilter();
    feed(f, t0, 50, rest);
    final start = t0.add(const Duration(seconds: 1));
    // 5 s of continuous shaking.
    final fired = feed(f, start, 250, violent);
    expect(fired, isNotEmpty);
    final firstMs = fired.first * dtMs;
    for (final i in fired.skip(1)) {
      expect(i * dtMs - firstMs, greaterThanOrEqualTo(3000));
    }
    expect(fired.length, 2, reason: 'one at start, one after debounce');
  });

  test('peak below threshold with many crossings does not trigger', () {
    final f = ShakeFilter(thresholdG: 5);
    feed(f, t0, 50, rest);
    expect(feed(f, t0.add(const Duration(seconds: 1)), 50, violent), isEmpty);
  });

  test('crossings spread outside the window do not accumulate', () {
    final f = ShakeFilter(windowMs: 100);
    feed(f, t0, 50, rest);
    // One strong swing every 400 ms, then back to rest.
    final fired = feed(f, t0.add(const Duration(seconds: 1)), 300, (i) {
      if (i % 20 == 0) return (3.5 * g, 0, g);
      if (i % 20 == 1) return (-3.5 * g, 0, g);
      return rest(i);
    });
    expect(fired, isEmpty);
  });

  test('reset clears state', () {
    final f = ShakeFilter();
    feed(f, t0, 50, rest);
    expect(feed(f, t0.add(const Duration(seconds: 1)), 25, violent), isNotEmpty);
    f.reset();
    feed(f, t0.add(const Duration(seconds: 2)), 5, rest);
    expect(feed(f, t0.add(const Duration(milliseconds: 2100)), 25, violent), isNotEmpty);
  });
}
