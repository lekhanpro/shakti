/// Detects a deliberate, violent shake from raw accelerometer samples.
///
/// Gravity is tracked per axis with a low-pass filter and subtracted, leaving
/// linear acceleration. A "strong" sample is one whose linear component on an
/// axis reaches [thresholdG]. Each time an axis flips sign between strong
/// samples it counts as a crossing. The filter fires when [minCrossings]
/// crossings land within [windowMs], then stays quiet for [debounceMs].
///
/// This rejects walking (well under threshold), and single drops or impacts
/// (one strong spike, no back-and-forth).
library;

class ShakeFilter {
  ShakeFilter({
    this.thresholdG = 2.8,
    this.windowMs = 750,
    this.minCrossings = 3,
    this.debounceMs = 3000,
    this.gravityAlpha = 0.8,
  });

  static const double _g = 9.80665;

  /// Minimum linear acceleration (in g) for a sample to count.
  final double thresholdG;

  /// Time window in which [minCrossings] must occur.
  final int windowMs;
  final int minCrossings;

  /// Quiet period after a trigger.
  final int debounceMs;

  /// Low-pass smoothing factor for the gravity estimate (0..1).
  final double gravityAlpha;

  List<double>? _gravity;
  final List<int> _lastSign = [0, 0, 0];
  final List<DateTime> _crossings = [];
  DateTime? _lastFire;

  /// Feeds one sample in m/s^2. Returns true when a shake is detected.
  bool push(double x, double y, double z, DateTime at) {
    final raw = [x, y, z];
    final gravity = _gravity ??= List.of(raw);
    final limit = thresholdG * _g;

    for (var axis = 0; axis < 3; axis++) {
      final linear = raw[axis] - gravity[axis];
      gravity[axis] = gravityAlpha * gravity[axis] + (1 - gravityAlpha) * raw[axis];
      if (linear.abs() < limit) continue;
      final sign = linear > 0 ? 1 : -1;
      if (_lastSign[axis] != 0 && _lastSign[axis] != sign) _crossings.add(at);
      _lastSign[axis] = sign;
    }

    final cutoff = at.subtract(Duration(milliseconds: windowMs));
    _crossings.removeWhere((t) => t.isBefore(cutoff));

    if (_crossings.length < minCrossings) return false;
    final last = _lastFire;
    if (last != null && at.difference(last).inMilliseconds < debounceMs) return false;
    _lastFire = at;
    return true;
  }

  /// Clears gravity estimate, crossing history and debounce.
  void reset() {
    _gravity = null;
    _lastSign.fillRange(0, 3, 0);
    _crossings.clear();
    _lastFire = null;
  }
}
