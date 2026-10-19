import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/power_press_detector.dart';

void main() {
  final t0 = DateTime(2026, 9, 29, 20);
  DateTime at(int ms) => t0.add(Duration(milliseconds: ms));

  test('three toggles inside 1200 ms fire exactly once', () {
    final d = PowerPressDetector();
    expect(d.onToggle(at(0)), isFalse);
    expect(d.onToggle(at(300)), isFalse);
    expect(d.onToggle(at(700)), isTrue);
    // Resets after firing.
    expect(d.onToggle(at(800)), isFalse);
    expect(d.onToggle(at(900)), isFalse);
  });

  test('stale toggles slide out of the window', () {
    final d = PowerPressDetector();
    expect(d.onToggle(at(0)), isFalse);
    expect(d.onToggle(at(1000)), isFalse);
    expect(d.onToggle(at(1300)), isFalse); // first one is now stale
    expect(d.onToggle(at(1500)), isTrue);
  });

  test('slow toggles never fire', () {
    final d = PowerPressDetector();
    for (var i = 0; i < 10; i++) {
      expect(d.onToggle(at(i * 700)), isFalse);
    }
  });

  test('toggle exactly at the window edge still counts', () {
    final d = PowerPressDetector();
    d.onToggle(at(0));
    d.onToggle(at(600));
    expect(d.onToggle(at(1200)), isTrue);
  });

  test('custom press count', () {
    final d = PowerPressDetector(presses: 5, window: const Duration(seconds: 2));
    for (var i = 0; i < 4; i++) {
      expect(d.onToggle(at(i * 100)), isFalse);
    }
    expect(d.onToggle(at(400)), isTrue);
  });

  test('reset clears pending toggles', () {
    final d = PowerPressDetector();
    d.onToggle(at(0));
    d.onToggle(at(100));
    d.reset();
    expect(d.onToggle(at(200)), isFalse);
  });
}
