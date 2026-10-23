import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/domain/entities/safety_settings.dart';

void main() {
  test('old and malformed settings select the light appearance', () {
    for (final input in <Map<String, Object?>>[{}, {'appearance': 'sepia'}, {'appearance': 42}]) {
      expect(SafetySettings.fromJson(input).appearance, AppearancePreference.light);
    }
  });

  test('every appearance survives JSON and preserves emergency preferences', () {
    const original = SafetySettings(stealthMode: true, recordAudio: false, powerTrigger: false);
    for (final appearance in AppearancePreference.values) {
      final restored = SafetySettings.fromJson(original.copyWith(appearance: appearance).toJson());
      expect(restored.appearance, appearance);
      expect(restored.stealthMode, isTrue);
      expect(restored.recordAudio, isFalse);
      expect(restored.powerTrigger, isFalse);
    }
  });
}
