/// Abstract ports for every platform capability. The domain and application
/// layers depend only on these; `lib/data/services` provides the plugin-backed
/// implementations and tests provide fakes.
library;

import '../../core/result.dart';
import '../entities/entities.dart';

/// An already available location; reading this must never start or await GPS.
abstract interface class CachedLocationService {
  LocationFix? get cachedFix;
}

abstract interface class EvidenceExportService {
  Future<Result<void>> share(String encryptedPath);
}

abstract interface class LocationService {
  /// Best-effort current fix. Must complete within [timeout]; falls back to the
  /// last known fix, else returns [Err].
  Future<Result<LocationFix>> currentFix({Duration timeout = const Duration(seconds: 4)});

  /// Continuous fixes (used by breadcrumb streaming and geofencing).
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)});

  Future<bool> ensurePermission({bool background = false});
}

abstract interface class SmsService {
  /// Sends [message] to every recipient. Returns the number actually handed to
  /// the carrier.
  Future<Result<int>> sendToAll(List<String> phones, String message);
  Future<bool> ensurePermission();
}

abstract interface class ConnectivityService {
  Future<bool> isOnline();
  Stream<bool> get onlineChanges;
}

abstract interface class BatteryService {
  Future<int?> level();
}

abstract interface class HapticsService {
  Future<void> tick();
  Future<void> heavy();
  Future<void> sosPattern();
  Future<void> cancel();
}

abstract interface class SirenService {
  Future<void> start();
  Future<void> stop();
  bool get isPlaying;
}

abstract interface class StrobeService {
  Future<bool> get available;
  Future<void> start({Duration period = const Duration(milliseconds: 120)});
  Future<void> stop();
}

abstract interface class AudioEvidenceService {
  /// Starts a covert encrypted recording that auto-stops after [duration].
  /// Resolves with the encrypted file path once finished.
  Future<Result<String>> record(String incidentId, {Duration duration = const Duration(seconds: 60)});
  Future<void> stop();
  Future<List<EvidenceItem>> list();

  /// Decrypts to a temp file for playback / sharing. Caller deletes it.
  Future<Result<String>> decryptToTemp(String encryptedPath);
  Future<void> delete(String encryptedPath);
}

abstract interface class GeocodingService {
  Future<String?> reverse(GeoPoint p);
}

abstract interface class CloudDispatchService {
  /// Calls the `emergency-dispatch` edge function (Telegram + push).
  Future<Result<void>> dispatch(Incident incident, {required String userName, String? telegramChatId});
  Future<Result<void>> notifyResolved(Incident incident, {required String userName, String? telegramChatId});
}

abstract interface class SyncService {
  Future<void> enqueueIncident(Incident incident);
  Future<void> enqueueBreadcrumb(Breadcrumb b);

  /// Drains the queue; returns number of rows synced.
  Future<int> flush();
}

abstract interface class AiService {
  Future<Result<String>> chat(List<ChatMessage> history, {GeoPoint? location});
  Future<Result<String>> draftFir(FirInput input);
}

abstract interface class HavenService {
  Future<Result<List<SafeHaven>>> nearby(GeoPoint center, {double radiusM = 5000});
}

abstract interface class RoutingService {
  Future<Result<List<WalkRoute>>> walkingRoutes(GeoPoint from, GeoPoint to);
}

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

abstract interface class BiometricService {
  Future<bool> get available;
  Future<bool> authenticate(String reason);
}

/// Bridge to the native Kotlin guard service (power/volume triggers,
/// FLAG_SECURE, foreground service).
abstract interface class NativeGuardService {
  Stream<TriggerSource> get triggers;
  Future<void> startGuard();
  Future<void> stopGuard();
  Future<void> setSecureScreen(bool on);
  Future<bool> isAccessibilityEnabled();
  Future<void> openAccessibilitySettings();
}

abstract interface class VoiceTriggerService {
  Future<bool> get available;
  Future<void> start(List<String> phrases, void Function() onMatch);
  Future<void> stop();
  bool get isListening;
}

abstract interface class ShakeSensorService {
  /// Raw accelerometer samples (m/s^2, including gravity).
  Stream<({double x, double y, double z, DateTime at})> get samples;
}

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}
