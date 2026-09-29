/// Dependency graph. Every port is declared here and throws until overridden.
/// Production overrides come from `lib/bootstrap.dart`; tests override with
/// fakes. Nothing outside `lib/data` and `lib/bootstrap.dart` may import a
/// concrete implementation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';

Never _missing(String name) =>
    throw UnimplementedError('$name not overridden. Add it in bootstrap.dart or the test ProviderScope.');

// Repositories
final contactRepositoryProvider = Provider<ContactRepository>((_) => _missing('ContactRepository'));
final incidentRepositoryProvider = Provider<IncidentRepository>((_) => _missing('IncidentRepository'));
final settingsRepositoryProvider = Provider<SettingsRepository>((_) => _missing('SettingsRepository'));
final havenCacheRepositoryProvider = Provider<HavenCacheRepository>((_) => _missing('HavenCacheRepository'));
final safePlaceRepositoryProvider = Provider<SafePlaceRepository>((_) => _missing('SafePlaceRepository'));
final chatRepositoryProvider = Provider<ChatRepository>((_) => _missing('ChatRepository'));

// Platform services
final locationServiceProvider = Provider<LocationService>((_) => _missing('LocationService'));
final smsServiceProvider = Provider<SmsService>((_) => _missing('SmsService'));
final connectivityServiceProvider = Provider<ConnectivityService>((_) => _missing('ConnectivityService'));
final batteryServiceProvider = Provider<BatteryService>((_) => _missing('BatteryService'));
final hapticsServiceProvider = Provider<HapticsService>((_) => _missing('HapticsService'));
final sirenServiceProvider = Provider<SirenService>((_) => _missing('SirenService'));
final strobeServiceProvider = Provider<StrobeService>((_) => _missing('StrobeService'));
final audioEvidenceServiceProvider = Provider<AudioEvidenceService>((_) => _missing('AudioEvidenceService'));
final geocodingServiceProvider = Provider<GeocodingService>((_) => _missing('GeocodingService'));
final cloudDispatchServiceProvider = Provider<CloudDispatchService>((_) => _missing('CloudDispatchService'));
final syncServiceProvider = Provider<SyncService>((_) => _missing('SyncService'));
final aiServiceProvider = Provider<AiService>((_) => _missing('AiService'));
final havenServiceProvider = Provider<HavenService>((_) => _missing('HavenService'));
final routingServiceProvider = Provider<RoutingService>((_) => _missing('RoutingService'));
final secureStoreProvider = Provider<SecureStore>((_) => _missing('SecureStore'));
final biometricServiceProvider = Provider<BiometricService>((_) => _missing('BiometricService'));
final nativeGuardServiceProvider = Provider<NativeGuardService>((_) => _missing('NativeGuardService'));
final voiceTriggerServiceProvider = Provider<VoiceTriggerService>((_) => _missing('VoiceTriggerService'));
final shakeSensorServiceProvider = Provider<ShakeSensorService>((_) => _missing('ShakeSensorService'));
final clockProvider = Provider<Clock>((_) => const SystemClock());
