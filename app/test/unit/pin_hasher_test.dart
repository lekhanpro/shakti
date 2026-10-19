import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/pin_hasher.dart';

void main() {
  group('hash / verify', () {
    test('format is v1\$iter\$salt\$hash with 16-byte salt and 32-byte hash', () async {
      final h = await PinHasher.hash('2580', iterations: 1000);
      final parts = h.split(r'$');
      expect(parts, hasLength(4));
      expect(parts[0], 'v1');
      expect(parts[1], '1000');
      expect(base64.decode(parts[2]), hasLength(16));
      expect(base64.decode(parts[3]), hasLength(32));
    });

    test('verify accepts the right PIN and rejects a wrong one', () async {
      final h = await PinHasher.hash('2580', iterations: 1000);
      expect(await PinHasher.verify('2580', h), isTrue);
      expect(await PinHasher.verify('2581', h), isFalse);
      expect(await PinHasher.verify('', h), isFalse);
    });

    test('random salt makes hashes differ', () async {
      final a = await PinHasher.hash('2580', iterations: 1000);
      final b = await PinHasher.hash('2580', iterations: 1000);
      expect(a, isNot(b));
    });

    test('fixed salt is deterministic and matches the PBKDF2-HMAC-SHA256 vector', () async {
      // RFC 7914 section 11 vector: P="passwd", S="salt", c=1, dkLen=64
      // (first 32 bytes).
      final h = await PinHasher.hash('passwd', iterations: 1, salt: utf8.encode('salt'));
      final hex = base64
          .decode(h.split(r'$')[3])
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      expect(hex, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
    });

    test('verify returns false on malformed input', () async {
      for (final bad in [
        '',
        'garbage',
        r'v2$1000$AAAA$AAAA',
        r'v1$abc$AAAA$AAAA',
        r'v1$0$AAAA$AAAA',
        r'v1$-5$AAAA$AAAA',
        r'v1$99999999999$AAAA$AAAA',
        r'v1$1000$!!!$AAAA',
        r'v1$1000$AAAA$***',
        r'v1$1000$$',
        r'v1$1000$AAAA$AAAA$extra',
      ]) {
        expect(await PinHasher.verify('1234', bad), isFalse, reason: bad);
      }
    });

    test('default 100k iterations round-trips', () async {
      final h = await PinHasher.hash('9173');
      expect(h, startsWith(r'v1$100000$'));
      expect(await PinHasher.verify('9173', h), isTrue);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  group('isValidPin', () {
    test('accepts 4-8 digit non-trivial PINs', () {
      for (final p in ['2580', '9173', '135790', '48151623', '1235', '1122']) {
        expect(PinHasher.isValidPin(p), isTrue, reason: p);
      }
    });

    test('rejects wrong length, non-digits, repeats and sequences', () {
      for (final p in [
        '',
        '123',
        '123456789',
        '12a4',
        ' 2580',
        '0000',
        '99999999',
        '1234',
        '0123',
        '4321',
        '987654',
        '12345678',
      ]) {
        expect(PinHasher.isValidPin(p), isFalse, reason: p);
      }
    });
  });
}
