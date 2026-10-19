import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../domain/entities/entities.dart';

/// Live settings for the Shield/lock/SOS screens.
final liveSettingsProvider = StreamProvider<SafetySettings>((ref) async* {
  final repo = ref.watch(settingsRepositoryProvider);
  yield await repo.load();
  yield* repo.watch();
});

/// Live trusted contacts, highest priority first.
final liveContactsProvider = StreamProvider<List<EmergencyContact>>((ref) {
  return ref.watch(contactRepositoryProvider).watchAll().map(
        (list) => [...list]..sort((a, b) => a.priority.compareTo(b.priority)),
      );
});

/// Secure-store keys for the PIN hashes (PinHasher encoded strings).
abstract final class PinKeys {
  static const primary = 'pin_hash';
  static const decoy = 'decoy_pin_hash';
}
