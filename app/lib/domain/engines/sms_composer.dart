/// Builds SOS / safe SMS bodies and counts carrier segments.
///
/// SOS bodies are kept to at most [SmsComposer.maxSosSegments] segments:
/// the address is truncated first, then dropped, so the maps link, track
/// link and "112" always survive.
library;

import '../entities/geo_point.dart';

abstract final class SmsComposer {
  static const int maxSosSegments = 3;
  static const int maxNameLength = 40;
  static const String fallbackName = 'A Shakti user';

  static const String _gsmBasic = '@£\$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !"#¤%&\'()*+,-./'
      '0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà';
  static const String _gsmExtension = '^{}\\[~]|€\f';

  static final Set<int> _basic = _gsmBasic.runes.toSet();
  static final Set<int> _ext = _gsmExtension.runes.toSet();

  /// Number of SMS segments [text] needs (GSM-7 or UCS-2).
  static int segments(String text) {
    if (text.isEmpty) return 0;
    var septets = 0;
    var gsm = true;
    for (final r in text.runes) {
      if (_basic.contains(r)) {
        septets += 1;
      } else if (_ext.contains(r)) {
        septets += 2;
      } else {
        gsm = false;
        break;
      }
    }
    if (gsm) return septets <= 160 ? 1 : (septets / 153).ceil();
    final units = text.length; // UTF-16 code units
    return units <= 70 ? 1 : (units / 67).ceil();
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Replaces smart punctuation with GSM-7 friendly ASCII and trims.
  static String _clean(String s) => s
      .replaceAll(RegExp('[‘’‚′]'), "'")
      .replaceAll(RegExp('[“”„″]'), '"')
      .replaceAll(RegExp('[–—−]'), '-')
      .replaceAll('…', '...')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _name(String raw) {
    final n = _clean(raw);
    if (n.isEmpty) return fallbackName;
    return n.length > maxNameLength ? n.substring(0, maxNameLength).trimRight() : n;
  }

  static String sos({
    required String userName,
    GeoPoint? location,
    String? address,
    int? battery,
    String? trackUrl,
    DateTime? at,
  }) {
    final time = _hhmm(at ?? DateTime.now());
    final hasFix = location != null && location.isValid;

    String build(String? addr) {
      final b = StringBuffer('SOS! ${_name(userName)} needs help.\n');
      b.write(hasFix ? 'Location: ${location.mapsUrl}\n' : 'Location unavailable\n');
      if (addr != null && addr.isNotEmpty) b.write('Near: $addr\n');
      if (battery != null) b.write('Battery: ${battery.clamp(0, 100)}%\n');
      if (trackUrl != null && trackUrl.isNotEmpty) b.write('Track live: $trackUrl\n');
      b.write('Sent $time. If unreachable, call 112.');
      return b.toString();
    }

    var addr = address == null ? '' : _clean(address);
    var msg = build(addr);
    if (segments(msg) <= maxSosSegments) return msg;

    // Binary search the longest address prefix that still fits.
    var lo = 0;
    var hi = addr.length;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (segments(build('${addr.substring(0, mid).trimRight()}...')) <= maxSosSegments) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    addr = lo > 0 ? '${addr.substring(0, lo).trimRight()}...' : '';
    msg = build(addr);
    return msg;
  }

  static String safe({required String userName, DateTime? at}) =>
      '${_name(userName)} is safe now. SOS cancelled at ${_hhmm(at ?? DateTime.now())}. - Shakti';
}
