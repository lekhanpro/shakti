import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/engines/voice_matcher.dart';

void main() {
  group('levenshtein', () {
    test('classic cases', () {
      expect(VoiceMatcher.levenshtein('', ''), 0);
      expect(VoiceMatcher.levenshtein('abc', ''), 3);
      expect(VoiceMatcher.levenshtein('', 'abc'), 3);
      expect(VoiceMatcher.levenshtein('kitten', 'sitting'), 3);
      expect(VoiceMatcher.levenshtein('shakti', 'shakthi'), 1);
      expect(VoiceMatcher.levenshtein('flaw', 'lawn'), 2);
      expect(VoiceMatcher.levenshtein('same', 'same'), 0);
    });
  });

  group('matches', () {
    const phrases = ['shakti help', 'help me now'];

    test('exact, case-insensitive, punctuation stripped', () {
      expect(VoiceMatcher.matches('Shakti, HELP!', phrases), isTrue);
      expect(VoiceMatcher.matches('please help me now.', phrases), isTrue);
    });

    test('tokens may be separated by other words, but must be in order', () {
      expect(VoiceMatcher.matches('shakti please help', phrases), isTrue);
      expect(VoiceMatcher.matches('help shakti', phrases), isFalse);
    });

    test('fuzzy within distance 1 for tokens longer than 3', () {
      expect(VoiceMatcher.matches('shakthi help', phrases), isTrue);
      expect(VoiceMatcher.matches('shak help', phrases), isFalse); // distance 2
    });

    test('short tokens must match exactly', () {
      expect(VoiceMatcher.matches('help mi now', phrases), isFalse);
      expect(VoiceMatcher.matches('help me nuw', phrases), isFalse);
    });

    test('length rule is based on the phrase token', () {
      // "help" has 4 characters, so a 1-edit transcript token is accepted.
      expect(VoiceMatcher.matches('shakti hel', phrases), isTrue);
      expect(VoiceMatcher.matches('help me know', phrases), isFalse);
    });

    test('non-matching and empty input', () {
      expect(VoiceMatcher.matches('', phrases), isFalse);
      expect(VoiceMatcher.matches('the weather is nice', phrases), isFalse);
      expect(VoiceMatcher.matches('shakti help', const []), isFalse);
      expect(VoiceMatcher.matches('shakti help', const ['', '  !! ']), isFalse);
    });
  });
}
