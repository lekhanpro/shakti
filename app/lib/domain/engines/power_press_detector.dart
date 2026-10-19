/// Detects N rapid power-button toggles (screen on/off events).
///
/// Keeps a sliding window of toggle timestamps. On each toggle, entries older
/// than [window] relative to the newest toggle are dropped; when [presses]
/// remain, the detector fires once and clears its history so the same burst
/// cannot fire twice. Defaults: 3 presses within 1200 ms, which is quick
/// enough to be deliberate yet reachable with a phone in a pocket.
library;

class PowerPressDetector {
  PowerPressDetector({this.presses = 3, this.window = const Duration(milliseconds: 1200)});

  final int presses;
  final Duration window;
  final List<DateTime> _toggles = [];

  /// Records a toggle at [at]. Returns true exactly once per qualifying burst.
  bool onToggle(DateTime at) {
    _toggles
      ..add(at)
      ..removeWhere((t) => at.difference(t) > window);
    if (_toggles.length >= presses) {
      _toggles.clear();
      return true;
    }
    return false;
  }

  void reset() => _toggles.clear();
}
