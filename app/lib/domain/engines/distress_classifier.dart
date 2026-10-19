/// Keyword-based distress detection for chat and community posts.
///
/// Matches whole words only (letters, digits and combining marks count as
/// word characters, so Devanagari and Kannada work too). Covers English plus
/// common Hindi and Kannada transliterations and native-script phrases.
/// Danger outranks concern.
library;

enum DistressLevel { none, concern, danger }

abstract final class DistressClassifier {
  static RegExp _words(List<String> alternatives) => RegExp(
        '(?<![\\p{L}\\p{N}\\p{M}])(?:${alternatives.join('|')})(?![\\p{L}\\p{N}\\p{M}])',
        unicode: true,
        caseSensitive: false,
      );

  static final _danger = _words([
    // English
    r'follow(?:ing|ed)\s+me',
    r'being\s+followed',
    r'attack(?:ed|ing)?',
    r'rap(?:e|ed|ing)',
    r'kidnap(?:ped|ping)?',
    r'abduct(?:ed|ing)?',
    r'knife',
    r'gun',
    r'help\s+me',
    r'kill\s+myself',
    r'suicid(?:e|al)',
    r'self[\s-]?harm',
    r'end\s+my\s+life',
    // Hindi (transliterated)
    r'bachao',
    r'bachaao',
    r'madad',
    r'pee?cha\s+kar',
    r'pichha\s+kar',
    // Kannada (transliterated)
    r'kaa?padi',
    r'sahaya',
    // Native script
    'बचाओ',
    'मदद',
    'ಕಾಪಾಡಿ',
    'ಸಹಾಯ',
  ]);

  static final _concern = _words([
    r'unsafe',
    r'scared',
    r'afraid',
    r'frightened',
    r'harass(?:ed|ment|ing)?',
    r'stalk(?:ed|er|ing)?',
    r'uncomfortable',
    r'threat(?:en|ened|ening|s)?',
    'डर',
    'ಭಯ',
  ]);

  static DistressLevel classify(String text) {
    if (text.trim().isEmpty) return DistressLevel.none;
    if (_danger.hasMatch(text)) return DistressLevel.danger;
    if (_concern.hasMatch(text)) return DistressLevel.concern;
    return DistressLevel.none;
  }
}
