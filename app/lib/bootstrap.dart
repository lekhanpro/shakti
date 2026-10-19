import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/di/providers.dart';
import 'data/local/app_database.dart';
import 'data/repositories/drift_repositories.dart';
import 'data/remote/nominatim_geocoding_service.dart';
import 'data/remote/osrm_routing_service.dart';
import 'data/remote/overpass_haven_service.dart';
import 'data/remote/supabase_functions.dart';
import 'data/services/native_guard_service.dart';
import 'data/services/platform_services.dart';
import 'data/services/platform_evidence.dart';
import 'data/services/sync_service_impl.dart';
import 'domain/services/services.dart';

Future<List<Override>> bootstrap() async {
  final db = AppDatabase.open();
  final connectivity = PlatformConnectivityService();
  final location = PlatformLocationService();
  const store = PlatformSecureStore();
  final audio = PlatformAudioEvidenceService(store);
  final siren = PlatformSirenService();
  unawaited(location.warmCache());
  try {
    await audio.cleanInterruptedFiles();
  } catch (_) {
    /* Storage cleanup must not prevent emergency startup. */
  }
  const url = String.fromEnvironment('SUPABASE_URL');
  const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
  SupabaseClient? client;
  if (url.isNotEmpty && anon.isNotEmpty) {
    await Supabase.initialize(url: url, publishableKey: anon);
    client = Supabase.instance.client;
  }
  final cloud = client;
  Future<void>? signingIn;
  Future<void> authenticate() async {
    if (cloud == null) throw StateError('Cloud backend is not configured');
    if (cloud.auth.currentSession != null) return;
    await (signingIn ??= cloud.auth
            .signInAnonymously()
            .then<void>((_) {})
            .whenComplete(() => signingIn = null))
        .timeout(const Duration(seconds: 12));
  }

  Future<({Object? data, int status})> invoke(String fn, Map<String, Object?> body) async {
    await authenticate();
    return supabaseInvoker(cloud!)(fn, body);
  }
  final sync = SyncServiceImpl(
    db,
    cloud == null
        ? const NullRemoteSink()
        : _AuthenticatedSink(cloud, authenticate),
    connectivity,
    const SystemClock(),
  );
  sync.start();
  final retry = Timer.periodic(const Duration(seconds: 15), (_) {
    unawaited(sync.flush().catchError((Object _) => 0));
  });
  return [
    contactRepositoryProvider.overrideWith((ref) {
      ref.onDispose(() {
        retry.cancel();
        unawaited(sync.dispose());
        unawaited(db.close());
        unawaited(siren.dispose());
      });
      return DriftContactRepository(db);
    }),
    incidentRepositoryProvider.overrideWithValue(DriftIncidentRepository(db)),
    settingsRepositoryProvider.overrideWithValue(DriftSettingsRepository(db)),
    havenCacheRepositoryProvider.overrideWithValue(
      DriftHavenCacheRepository(db),
    ),
    safePlaceRepositoryProvider.overrideWithValue(DriftSafePlaceRepository(db)),
    chatRepositoryProvider.overrideWithValue(DriftChatRepository(db)),
    locationServiceProvider.overrideWithValue(location),
    smsServiceProvider.overrideWithValue(PlatformSmsService()),
    connectivityServiceProvider.overrideWithValue(connectivity),
    batteryServiceProvider.overrideWithValue(PlatformBatteryService()),
    hapticsServiceProvider.overrideWithValue(PlatformHapticsService()),
    sirenServiceProvider.overrideWithValue(siren),
    strobeServiceProvider.overrideWithValue(PlatformStrobeService()),
    audioEvidenceServiceProvider.overrideWithValue(audio),
    evidenceExportServiceProvider.overrideWithValue(
      PlatformEvidenceExportService(audio),
    ),
    geocodingServiceProvider.overrideWithValue(NominatimGeocodingService()),
    cloudDispatchServiceProvider.overrideWithValue(
      cloud == null
          ? const OfflineCloudDispatch()
          : SupabaseCloudDispatchService(invoke),
    ),
    syncServiceProvider.overrideWithValue(sync),
    aiServiceProvider.overrideWithValue(
      cloud == null ? const OfflineAiService() : SupabaseAiService(invoke),
    ),
    havenServiceProvider.overrideWithValue(OverpassHavenService()),
    routingServiceProvider.overrideWithValue(OsrmRoutingService()),
    secureStoreProvider.overrideWithValue(store),
    biometricServiceProvider.overrideWithValue(PlatformBiometricService()),
    nativeGuardServiceProvider.overrideWithValue(
      MethodChannelNativeGuardService(),
    ),
    voiceTriggerServiceProvider.overrideWithValue(
      PlatformVoiceTriggerService(),
    ),
    shakeSensorServiceProvider.overrideWithValue(PlatformShakeSensorService()),
  ];
}

class _AuthenticatedSink implements RemoteSink {
  _AuthenticatedSink(SupabaseClient client, this.authenticate)
    : sink = SupabaseRemoteSink(client);
  final SupabaseRemoteSink sink;
  final Future<void> Function() authenticate;
  @override
  Future<void> upsertIncident(Map<String, Object?> row) async {
    await authenticate();
    await sink.upsertIncident(row);
  }

  @override
  Future<void> insertBreadcrumbs(List<Map<String, Object?>> rows) async {
    await authenticate();
    await sink.insertBreadcrumbs(rows);
  }
}
