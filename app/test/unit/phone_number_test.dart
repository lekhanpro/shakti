import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/phone_number.dart';

void main() {
  group('normalize', () {
    test('10-digit Indian mobile gets +91', () {
      expect(PhoneNumber.normalize('98450 12345'), '+919845012345');
      expect(PhoneNumber.normalize('(984) 501-2345'), '+919845012345');
      expect(PhoneNumber.normalize('6000000001'), '+916000000001');
    });

    test('0-prefixed 11 digits become +91', () {
      expect(PhoneNumber.normalize('09845012345'), '+919845012345');
      expect(PhoneNumber.normalize('080-2222-3333'), '+918022223333');
    });

    test('existing + code is kept', () {
      expect(PhoneNumber.normalize('+91 98450 12345'), '+919845012345');
      expect(PhoneNumber.normalize('+1 (415) 555-0100'), '+14155550100');
      expect(PhoneNumber.normalize('+44 20 7946 0958'), '+442079460958');
    });

    test('00 international prefix becomes +', () {
      expect(PhoneNumber.normalize('0044 20 7946 0958'), '+442079460958');
    });

    test('12 digits starting 91 get a +', () {
      expect(PhoneNumber.normalize('919845012345'), '+919845012345');
    });

    test('helplines and other input are left as stripped digits', () {
      expect(PhoneNumber.normalize(' 112 '), '112');
      expect(PhoneNumber.normalize('1091'), '1091');
      expect(PhoneNumber.normalize('5845012345'), '5845012345');
      expect(PhoneNumber.normalize(''), '');
    });
  });

  group('isValid', () {
    test('valid numbers', () {
      for (final n in [
        '9845012345',
        '+91 98450 12345',
        '09845012345',
        '+14155550100',
        '+4930123456',
        '112',
        '181',
        '1091',
        '1098',
        '100',
      ]) {
        expect(PhoneNumber.isValid(n), isTrue, reason: n);
      }
    });

    test('invalid numbers', () {
      for (final n in [
        '',
        '12345',
        '5845012345',
        '+1234567',
        '+1234567890123456',
        '98450abcde',
        '+91 98450 1234x',
        '999',
        'call me',
      ]) {
        expect(PhoneNumber.isValid(n), isFalse, reason: n);
      }
    });
  });
}
