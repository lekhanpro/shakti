/// PIN hashing with PBKDF2-HMAC-SHA256.
///
/// Encoded form: `v1$<iterations>$<base64 salt>$<base64 32-byte hash>`.
/// Hashing runs in a background isolate so 100k iterations never block UI.
library;

import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

abstract final class PinHasher {
  static const int defaultIterations = 100000;
  static const int maxIterations = 10000000;
  static const int saltLength = 16;
  static const int hashLength = 32;

  static Future<String> hash(
    String pin, {
    int iterations = defaultIterations,
    List<int>? salt,
  }) async {
    if (iterations < 1 || iterations > maxIterations) {
      throw ArgumentError.value(iterations, 'iterations');
    }
    final s = Uint8List.fromList(salt ?? _randomSalt());
    final dk = await Isolate.run(() => _pbkdf2(utf8.encode(pin), s, iterations));
    return 'v1\$$iterations\$${base64.encode(s)}\$${base64.encode(dk)}';
  }

  /// Returns false for a wrong PIN or any malformed [encoded] value.
  static Future<bool> verify(String pin, String encoded) async {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != 'v1') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations < 1 || iterations > maxIterations) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on FormatException {
      return false;
    }
    if (salt.isEmpty || expected.length != hashLength) return false;
    final actual = await Isolate.run(() => _pbkdf2(utf8.encode(pin), salt, iterations));
    return _constantTimeEquals(actual, expected);
  }

  /// 4-8 digits, not all the same digit, not a straight run (1234, 4321).
  static bool isValidPin(String pin) {
    if (!RegExp(r'^[0-9]{4,8}$').hasMatch(pin)) return false;
    final d = pin.codeUnits;
    if (d.every((c) => c == d.first)) return false;
    bool run(int step) {
      for (var i = 1; i < d.length; i++) {
        if (d[i] - d[i - 1] != step) return false;
      }
      return true;
    }

    return !run(1) && !run(-1);
  }

  static List<int> _randomSalt() {
    final r = Random.secure();
    return List<int>.generate(saltLength, (_) => r.nextInt(256));
  }

  /// PBKDF2 with a single output block (dkLen = 32 = SHA-256 size).
  static Uint8List _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final mac = Hmac(sha256, password);
    var u = mac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = mac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
