/// Phone number normalisation for India-first contacts.
///
/// [PhoneNumber.normalize] strips spaces, dashes, dots and brackets and then:
/// - keeps an explicit `+<country code>` number,
/// - turns a `00` international prefix into `+`,
/// - maps a 10-digit Indian mobile (first digit 6-9) to `+91XXXXXXXXXX`,
/// - maps an 11-digit trunk-prefixed number (`0XXXXXXXXXX`) to `+91...`,
/// - maps a 12-digit `91XXXXXXXXXX` mobile to `+91...`,
/// - otherwise returns the stripped string unchanged.
///
/// [PhoneNumber.isValid] accepts E.164 (`+` then 8-15 digits, first digit
/// non-zero) after normalisation, plus the Indian short-code helplines.
library;

abstract final class PhoneNumber {
  /// 3-4 digit emergency short codes that are dialable without a prefix.
  static const helplines = {'100', '101', '102', '108', '112', '181', '1091', '1098'};

  static final _strip = RegExp(r'[\s\-(). ]');
  static final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');
  static final _inMobile = RegExp(r'^[6-9]\d{9}$');

  static String normalize(String raw) {
    final s = raw.trim().replaceAll(_strip, '');
    if (s.startsWith('+')) return s;
    if (s.startsWith('00') && s.length > 2) return '+${s.substring(2)}';
    if (_inMobile.hasMatch(s)) return '+91$s';
    if (s.length == 11 && s.startsWith('0')) return '+91${s.substring(1)}';
    if (s.length == 12 && s.startsWith('91') && _inMobile.hasMatch(s.substring(2))) return '+$s';
    return s;
  }

  static bool isValid(String raw) {
    final n = normalize(raw);
    return helplines.contains(n) || _e164.hasMatch(n);
  }
}
