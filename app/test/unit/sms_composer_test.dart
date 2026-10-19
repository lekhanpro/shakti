import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/sms_composer.dart';
import 'package:shakti/domain/entities/entities.dart';

void main() {
  final at = DateTime(2026, 9, 29, 21, 5);
  const loc = GeoPoint(12.9716, 77.5946);

  group('segments', () {
    test('GSM-7 single and multipart', () {
      expect(SmsComposer.segments(''), 0);
      expect(SmsComposer.segments('a' * 160), 1);
      expect(SmsComposer.segments('a' * 161), 2);
      expect(SmsComposer.segments('a' * 306), 2);
      expect(SmsComposer.segments('a' * 307), 3);
      expect(SmsComposer.segments('a' * 459), 3);
      expect(SmsComposer.segments('a' * 460), 4);
    });

    test('GSM-7 extension characters count double', () {
      expect(SmsComposer.segments('{' * 80), 1);
      expect(SmsComposer.segments('{' * 81), 2);
      expect(SmsComposer.segments('${'a' * 159}€'), 2);
    });

    test('GSM-7 basic set includes accented and Greek letters', () {
      expect(SmsComposer.segments('é£¥ΔΩ@' * 26), 1);
    });

    test('UCS-2 for anything outside GSM-7', () {
      expect(SmsComposer.segments('अ' * 70), 1);
      expect(SmsComposer.segments('अ' * 71), 2);
      expect(SmsComposer.segments('${'a' * 70}ç'), 2); // ç (lowercase) is not GSM-7
      expect(SmsComposer.segments('a' * 134 + 'अ'), 3);
      expect(SmsComposer.segments('😀' * 35), 1); // surrogate pairs = 2 units
      expect(SmsComposer.segments('😀' * 36), 2);
    });
  });

  group('sos', () {
    test('contains name, maps link, battery, track link, time and 112', () {
      final s = SmsComposer.sos(
        userName: 'Priya',
        location: loc,
        address: 'MG Road, Bengaluru',
        battery: 42,
        trackUrl: 'https://shakti.app/t/abc123',
        at: at,
      );
      expect(s, contains('SOS'));
      expect(s, contains('Priya'));
      expect(s, contains(loc.mapsUrl));
      expect(s, contains('MG Road, Bengaluru'));
      expect(s, contains('42%'));
      expect(s, contains('https://shakti.app/t/abc123'));
      expect(s, contains('21:05'));
      expect(s, contains('112'));
      expect(SmsComposer.segments(s), lessThanOrEqualTo(3));
      expect(RegExp(r'[^\x20-\x7E\n]').hasMatch(s), isFalse, reason: 'plain ASCII');
    });

    test('says Location unavailable without a fix', () {
      final s = SmsComposer.sos(userName: 'Priya', at: at);
      expect(s, contains('Location unavailable'));
      expect(s, isNot(contains('maps.google')));
      expect(s, isNot(contains('Battery')));
    });

    test('invalid coordinates count as unavailable', () {
      final s = SmsComposer.sos(userName: 'Priya', location: const GeoPoint(200, 0), at: at);
      expect(s, contains('Location unavailable'));
    });

    test('long address is truncated to fit 3 segments', () {
      final address = 'Very long street name, ' * 40;
      final s = SmsComposer.sos(
        userName: 'Priya',
        location: loc,
        address: address,
        battery: 9,
        trackUrl: 'https://shakti.app/t/abc123',
        at: at,
      );
      expect(SmsComposer.segments(s), lessThanOrEqualTo(3));
      expect(s, contains(loc.mapsUrl));
      expect(s, contains('https://shakti.app/t/abc123'));
      expect(s, contains('112'));
      expect(s, contains('Very long street'));
    });

    test('non-GSM address and name still fit in 3 UCS-2 segments', () {
      final s = SmsComposer.sos(
        userName: 'ಪ್ರಿಯಾ ಶರ್ಮಾ',
        location: loc,
        address: 'ಮಹಾತ್ಮ ಗಾಂಧಿ ರಸ್ತೆ, ಬೆಂಗಳೂರು, ಕರ್ನಾಟಕ ' * 10,
        battery: 50,
        trackUrl: 'https://shakti.app/t/abc123',
        at: at,
      );
      expect(SmsComposer.segments(s), lessThanOrEqualTo(3));
      expect(s, contains(loc.mapsUrl));
      expect(s, contains('112'));
    });

    test('absurdly long name is truncated too', () {
      final s = SmsComposer.sos(userName: 'N' * 600, location: loc, at: at);
      expect(SmsComposer.segments(s), lessThanOrEqualTo(3));
      expect(s, contains(loc.mapsUrl));
    });

    test('smart punctuation in address is made GSM-7 friendly', () {
      final s = SmsComposer.sos(
          userName: 'Priya', location: loc, address: 'St. Mark’s Rd – Near “Cafe”', at: at);
      expect(s, contains("St. Mark's Rd - Near \"Cafe\""));
    });

    test('blank name falls back', () {
      final s = SmsComposer.sos(userName: '  ', at: at);
      expect(s, contains('A Shakti user'));
    });
  });

  test('safe message', () {
    final s = SmsComposer.safe(userName: 'Priya', at: at);
    expect(s, contains('Priya'));
    expect(s, contains('safe'));
    expect(s, contains('21:05'));
    expect(SmsComposer.segments(s), 1);
  });
}
