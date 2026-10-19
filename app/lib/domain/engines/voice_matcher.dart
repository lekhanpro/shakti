/// Fuzzy keyword matching over speech-to-text transcripts.
///
/// Both transcript and phrase are lower-cased, punctuation is replaced by
/// spaces and the text is split into tokens. A phrase matches when its tokens
/// appear in the transcript in order (other words may sit in between). Each
/// phrase token longer than 3 characters tolerates Levenshtein distance 1
/// (STT often renders "shakti" as "shakthi"); tokens of 3 or fewer characters
/// must match exactly, since one edit would change a short word entirely.
library;

import 'dart:math' as math;

abstract final class VoiceMatcher {
  static final _nonWord = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);

  static List<String> _tokens(String s) =>
      s.toLowerCase().split(_nonWord).where((t) => t.isNotEmpty).toList();

  static bool _tokenMatch(String phraseTok, String heard) =>
      phraseTok.length > 3 ? levenshtein(phraseTok, heard) <= 1 : phraseTok == heard;

  static bool matches(String transcript, List<String> phrases) {
    final heard = _tokens(transcript);
    if (heard.isEmpty) return false;
    for (final phrase in phrases) {
      final want = _tokens(phrase);
      if (want.isEmpty) continue;
      var i = 0;
      for (final h in heard) {
        if (_tokenMatch(want[i], h) && ++i == want.length) return true;
      }
    }
    return false;
  }

  /// Edit distance (insert, delete, substitute) using two rolling rows.
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (j) => j);
    var cur = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      final t = prev;
      prev = cur;
      cur = t;
    }
    return prev[b.length];
  }
}
