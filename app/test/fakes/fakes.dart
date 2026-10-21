/// In-memory fakes for every port in `lib/domain/services/services.dart` and
/// `lib/domain/repositories/repositories.dart`.
///
/// Depends only on the domain, core and flutter_riverpod so it compiles
/// independently of `lib/data`.
library;

import 'dart:async';

import 'package:flutter_riverpod/misc.dart';
import 'package:shakti/core/di/providers.dart';
import 'package:shakti/core/result.dart';
import 'package:shakti/domain/entities/entities.dart';
import 'package:shakti/domain/repositories/repositories.dart';
import 'package:shakti/domain/services/services.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// A broadcast "behaviour subject": every new listener immediately receives
/// the current value, then all later updates.
class _Subject<T> {
  _Subject(this._value);

  T _value;
  final _controller = StreamController<T>.broadcast(sync: true);

  T get value => _value;

  set value(T v) {
    _value = v;
    _controller.add(v);
  }

  Stream<T> get stream async* {
    yield _value;
    yield* _controller.stream;
  }
}

final _fixedNow = DateTime(2026, 9, 29, 10);

// ---------------------------------------------------------------------------
// Platform services
// ---------------------------------------------------------------------------

class FakeLocationService implements LocationService, CachedLocationService {
  FakeLocationService({LocationFix? fix}) : fix = fix ?? defaultFix;

  static final defaultFix = LocationFix(
    point: const GeoPoint(12.9716, 77.5946),
    at: _fixedNow,
    speedKmh: 0,
    accuracyM: 8,
  );

  /// Returned by [currentFix] unless [error] is set. Null yields an Err.
  LocationFix? fix;

  @override
  LocationFix? get cachedFix => error == null ? fix : null;

  /// When non-null, [currentFix] returns `Err(error)`.
  String? error;

  /// Artificial latency applied to [currentFix].
  Duration? delay;

  bool permission = true;
  int currentFixCalls = 0;
  Duration? lastWatchInterval;
  final watchController = StreamController<LocationFix>.broadcast();

  @override
  Future<Result<LocationFix>> currentFix({Duration timeout = const Duration(seconds: 4)}) async {
    currentFixCalls++;
    final d = delay;
    if (d != null) await Future<void>.delayed(d);
    final e = error;
    if (e != null) return Err(e);
    final f = fix;
    return f == null ? const Err('No location fix') : Ok(f);
  }

  @override
  Stream<LocationFix> watch({Duration interval = const Duration(seconds: 10)}) {
    lastWatchInterval = interval;
    return watchController.stream;
  }

  @override
  Future<bool> ensurePermission({bool background = false}) async => permission;
}

class FakeSmsService implements SmsService {
  Completer<Result<int>>? pendingResult;
  final List<(List<String>, String)> sent = [];

  /// When non-null, [sendToAll] returns `Err(failWith)` and records nothing.
  String? failWith;

  /// Overrides the returned count; defaults to the number of recipients.
  int? result;
  bool permission = true;

  @override
  Future<Result<int>> sendToAll(List<String> phones, String message) async {
    final f = failWith;
    if (f != null) return Err(f);
    sent.add((List.of(phones), message));
    if (pendingResult != null) return pendingResult!.future;
    return Ok(result ?? phones.length);
  }

  @override
  Future<bool> ensurePermission() async => permission;
}

class FakeConnectivity implements ConnectivityService {
  FakeConnectivity({this.online = true});

  bool online;
  final controller = StreamController<bool>.broadcast();

  /// Updates [online] and emits the change.
  void set(bool value) {
    online = value;
    controller.add(value);
  }

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => controller.stream;
}

class FakeClock implements Clock {
  FakeClock([DateTime? now]) : current = now ?? _fixedNow;

  /// The time returned by [now]; settable directly.
  DateTime current;

  @override
  DateTime now() => current;

  void advance(Duration d) => current = current.add(d);
}

class FakeBattery implements BatteryService {
  int? levelValue = 80;

  @override
  Future<int?> level() async => levelValue;
}

class FakeHaptics implements HapticsService {
  int ticks = 0;
  int heavies = 0;
  int sosPatterns = 0;
  int cancels = 0;

  @override
  Future<void> tick() async => ticks++;

  @override
  Future<void> heavy() async => heavies++;

  @override
  Future<void> sosPattern() async => sosPatterns++;

  @override
  Future<void> cancel() async => cancels++;
}

class FakeSiren implements SirenService {
  int starts = 0;
  int stops = 0;
  bool _playing = false;

  @override
  bool get isPlaying => _playing;

  @override
  Future<void> start() async {
    starts++;
    _playing = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    _playing = false;
  }
}

class FakeStrobe implements StrobeService {
  bool isAvailable = true;
  bool isOn = false;
  int starts = 0;
  int stops = 0;
  Duration? lastPeriod;

  @override
  Future<bool> get available async => isAvailable;

  @override
  Future<void> start({Duration period = const Duration(milliseconds: 120)}) async {
    starts++;
    lastPeriod = period;
    isOn = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    isOn = false;
  }
}

class FakeAudioEvidence implements AudioEvidenceService {
  final List<EvidenceItem> items = [];

  /// Returned by [record] (unless [recordCompleter] is set).
  Result<String>? recordResult;

  /// When set, [record] waits on this completer instead.
  Completer<Result<String>>? recordCompleter;

  final List<String> recordedIncidentIds = [];
  final List<String> deleted = [];
  int stops = 0;

  /// When non-null, [decryptToTemp] returns it; otherwise `Ok('<path>.tmp')`.
  Result<String>? decryptResult;

  @override
  Future<Result<String>> record(String incidentId, {Duration duration = const Duration(seconds: 60)}) async {
    recordedIncidentIds.add(incidentId);
    final c = recordCompleter;
    if (c != null) return c.future;
    return recordResult ?? Ok('/evidence/${incidentId}_0.m4a.enc');
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<List<EvidenceItem>> list() async => List.of(items);

  @override
  Future<Result<String>> decryptToTemp(String encryptedPath) async =>
      decryptResult ?? Ok('$encryptedPath.tmp');

  @override
  Future<void> delete(String encryptedPath) async {
    deleted.add(encryptedPath);
    items.removeWhere((e) => e.path == encryptedPath);
  }
}

class FakeGeocoding implements GeocodingService {
  String? address = 'MG Road, Bengaluru';
  final List<GeoPoint> calls = [];

  @override
  Future<String?> reverse(GeoPoint p) async {
    calls.add(p);
    return address;
  }
}

class FakeCloudDispatch implements CloudDispatchService {
  final List<Incident> calls = [];
  final List<Incident> resolvedCalls = [];
  Result<void> result = const Ok(null);
  String? lastUserName;
  String? lastTelegramChatId;

  @override
  Future<Result<void>> dispatch(Incident incident, {required String userName, String? telegramChatId}) async {
    calls.add(incident);
    lastUserName = userName;
    lastTelegramChatId = telegramChatId;
    return result;
  }

  @override
  Future<Result<void>> notifyResolved(Incident incident,
      {required String userName, String? telegramChatId}) async {
    resolvedCalls.add(incident);
    lastUserName = userName;
    lastTelegramChatId = telegramChatId;
    return result;
  }
}

class FakeSync implements SyncService {
  final List<Incident> incidents = [];
  final List<Breadcrumb> breadcrumbs = [];
  int flushCount = 0;

  /// Returned by [flush].
  int flushResult = 0;

  @override
  Future<void> enqueueIncident(Incident incident) async => incidents.add(incident);

  @override
  Future<void> enqueueBreadcrumb(Breadcrumb b) async => breadcrumbs.add(b);

  @override
  Future<int> flush() async {
    flushCount++;
    return flushResult;
  }
}

class FakeAi implements AiService {
  /// Replies handed out in order by [chat]. When empty, `Ok('OK')`.
  final List<String> replies = [];

  /// When non-null, [chat] and [draftFir] return `Err(error)`.
  String? error;
  Result<String> firResult = const Ok('FIR DRAFT');

  final List<List<ChatMessage>> chatCalls = [];
  final List<GeoPoint?> locations = [];
  final List<FirInput> firCalls = [];

  @override
  Future<Result<String>> chat(List<ChatMessage> history, {GeoPoint? location}) async {
    chatCalls.add(List.of(history));
    locations.add(location);
    final e = error;
    if (e != null) return Err(e);
    return Ok(replies.isEmpty ? 'OK' : replies.removeAt(0));
  }

  @override
  Future<Result<String>> draftFir(FirInput input) async {
    firCalls.add(input);
    final e = error;
    if (e != null) return Err(e);
    return firResult;
  }
}

class FakeHavenService implements HavenService {
  List<SafeHaven> havens = const [
    SafeHaven(
      id: 'osm:node/1',
      name: 'Cubbon Park Police Station',
      category: HavenCategory.police,
      point: GeoPoint(12.9763, 77.5929),
      phone: '100',
      open24h: true,
    ),
    SafeHaven(
      id: 'osm:node/2',
      name: 'Bowring Hospital',
      category: HavenCategory.hospital,
      point: GeoPoint(12.9830, 77.6050),
      open24h: true,
    ),
  ];

  String? error;
  final List<(GeoPoint, double)> calls = [];

  @override
  Future<Result<List<SafeHaven>>> nearby(GeoPoint center, {double radiusM = 5000}) async {
    calls.add((center, radiusM));
    final e = error;
    if (e != null) return Err(e);
    return Ok(List.of(havens));
  }
}

class FakeRouting implements RoutingService {
  List<WalkRoute> routes = const [
    WalkRoute(
      points: [GeoPoint(12.9716, 77.5946), GeoPoint(12.9763, 77.5929)],
      distanceM: 600,
      durationS: 450,
    ),
  ];
  String? error;
  final List<(GeoPoint, GeoPoint)> calls = [];

  @override
  Future<Result<List<WalkRoute>>> walkingRoutes(GeoPoint from, GeoPoint to) async {
    calls.add((from, to));
    final e = error;
    if (e != null) return Err(e);
    return Ok(List.of(routes));
  }
}

class FakeSecureStore implements SecureStore {
  final Map<String, String> map = {};

  @override
  Future<String?> read(String key) async => map[key];

  @override
  Future<void> write(String key, String value) async => map[key] = value;

  @override
  Future<void> delete(String key) async => map.remove(key);
}

class FakeBiometric implements BiometricService {
  bool isAvailable = true;
  bool succeed = true;
  final List<String> reasons = [];

  @override
  Future<bool> get available async => isAvailable;

  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return succeed;
  }
}

class FakeNativeGuard implements NativeGuardService {
  final triggerController = StreamController<TriggerSource>.broadcast();
  bool started = false;
  bool secureScreen = false;
  bool accessibilityEnabled = false;
  int startCalls = 0;
  int stopCalls = 0;
  int openAccessibilityCalls = 0;

  /// Emits a native trigger.
  void fire(TriggerSource s) => triggerController.add(s);

  @override
  Stream<TriggerSource> get triggers => triggerController.stream;

  @override
  Future<void> startGuard() async {
    startCalls++;
    started = true;
  }

  @override
  Future<void> stopGuard() async {
    stopCalls++;
    started = false;
  }

  @override
  Future<void> setSecureScreen(bool on) async => secureScreen = on;

  @override
  Future<bool> isAccessibilityEnabled() async => accessibilityEnabled;

  @override
  Future<void> openAccessibilitySettings() async => openAccessibilityCalls++;
}

class FakeVoice implements VoiceTriggerService {
  bool isAvailable = true;
  bool _listening = false;
  List<String> phrases = const [];
  void Function()? onMatch;
  int starts = 0;
  int stops = 0;

  /// Simulates a keyword match.
  void fire() => onMatch?.call();

  @override
  Future<bool> get available async => isAvailable;

  @override
  bool get isListening => _listening;

  @override
  Future<void> start(List<String> phrases, void Function() onMatch) async {
    starts++;
    this.phrases = List.of(phrases);
    this.onMatch = onMatch;
    _listening = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    _listening = false;
    onMatch = null;
  }
}

typedef ShakeSample = ({double x, double y, double z, DateTime at});

class FakeShakeSensor implements ShakeSensorService {
  final controller = StreamController<ShakeSample>.broadcast();

  void emit(double x, double y, double z, DateTime at) => controller.add((x: x, y: y, z: z, at: at));

  @override
  Stream<ShakeSample> get samples => controller.stream;
}

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

class FakeContactRepository implements ContactRepository {
  FakeContactRepository([List<EmergencyContact> initial = const []]) : _s = _Subject(List.of(initial));

  final _Subject<List<EmergencyContact>> _s;

  List<EmergencyContact> get contacts => _s.value;
  set contacts(List<EmergencyContact> v) => _s.value = List.of(v);

  @override
  Stream<List<EmergencyContact>> watchAll() => _s.stream;

  @override
  Future<List<EmergencyContact>> active() async =>
      (_s.value.where((c) => c.isActive).toList()..sort((a, b) => a.priority.compareTo(b.priority)));

  @override
  Future<void> upsert(EmergencyContact c) async {
    final list = List.of(_s.value);
    final i = list.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      list[i] = c;
    } else {
      list.add(c);
    }
    _s.value = list;
  }

  @override
  Future<void> delete(String id) async => _s.value = _s.value.where((e) => e.id != id).toList();
}

class FakeIncidentRepository implements IncidentRepository {
  final _Subject<List<Incident>> _s = _Subject(<Incident>[]);
  final Map<String, List<Breadcrumb>> crumbs = {};
  int saveCount = 0;

  /// Newest first.
  List<Incident> get incidents => _s.value;
  set incidents(List<Incident> v) => _s.value = _sorted(v);

  List<Breadcrumb> get allBreadcrumbs => crumbs.values.expand((e) => e).toList();

  static List<Incident> _sorted(List<Incident> v) =>
      List.of(v)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Incident>> watchAll() => _s.stream;

  @override
  Future<Incident?> byId(String id) async {
    for (final i in _s.value) {
      if (i.id == id) return i;
    }
    return null;
  }

  @override
  Future<Incident?> latestOpen() async {
    for (final i in _s.value) {
      if (i.isOpen) return i;
    }
    return null;
  }

  @override
  Future<void> save(Incident i) async {
    saveCount++;
    _s.value = _sorted([..._s.value.where((e) => e.id != i.id), i]);
  }

  @override
  Future<void> addBreadcrumb(Breadcrumb b) async => (crumbs[b.incidentId] ??= []).add(b);

  @override
  Future<List<Breadcrumb>> breadcrumbs(String incidentId) async =>
      List.of(crumbs[incidentId] ?? const <Breadcrumb>[]);
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([SafetySettings initial = const SafetySettings()]) : _s = _Subject(initial);

  final _Subject<SafetySettings> _s;
  int saveCount = 0;
  bool failLoad = false;

  SafetySettings get settings => _s.value;
  set settings(SafetySettings v) => _s.value = v;

  @override
  Future<SafetySettings> load() async {
    if (failLoad) throw StateError('Settings storage unavailable');
    return _s.value;
  }

  @override
  Future<void> save(SafetySettings s) async {
    saveCount++;
    _s.value = s;
  }

  @override
  Stream<SafetySettings> watch() => _s.stream;
}

class FakeHavenCache implements HavenCacheRepository {
  List<SafeHaven> havens = [];
  int replaceCount = 0;

  @override
  Future<List<SafeHaven>> cached() async => List.of(havens);

  @override
  Future<void> replaceAll(List<SafeHaven> havens) async {
    replaceCount++;
    this.havens = List.of(havens);
  }
}

class FakeSafePlaceRepository implements SafePlaceRepository {
  final _Subject<List<SafePlace>> _s = _Subject(<SafePlace>[]);

  List<SafePlace> get places => _s.value;
  set places(List<SafePlace> v) => _s.value = List.of(v);

  @override
  Stream<List<SafePlace>> watchAll() => _s.stream;

  @override
  Future<List<SafePlace>> all() async => List.of(_s.value);

  @override
  Future<void> upsert(SafePlace p) async {
    final list = List.of(_s.value);
    final i = list.indexWhere((e) => e.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    _s.value = list;
  }

  @override
  Future<void> delete(String id) async => _s.value = _s.value.where((e) => e.id != id).toList();
}

class FakeChatRepository implements ChatRepository {
  final _Subject<List<ChatMessage>> _s = _Subject(<ChatMessage>[]);

  List<ChatMessage> get messages => _s.value;

  @override
  Stream<List<ChatMessage>> watchAll() => _s.stream;

  @override
  Future<void> add(ChatMessage m) async => _s.value = [..._s.value, m];

  @override
  Future<void> clear() async => _s.value = <ChatMessage>[];
}

// ---------------------------------------------------------------------------
// Bundle
// ---------------------------------------------------------------------------

class Fakes {
  final contacts = FakeContactRepository();
  final incidents = FakeIncidentRepository();
  final settings = FakeSettingsRepository();
  final havenCache = FakeHavenCache();
  final safePlaces = FakeSafePlaceRepository();
  final chat = FakeChatRepository();

  final location = FakeLocationService();
  final sms = FakeSmsService();
  final connectivity = FakeConnectivity();
  final battery = FakeBattery();
  final haptics = FakeHaptics();
  final siren = FakeSiren();
  final strobe = FakeStrobe();
  final audio = FakeAudioEvidence();
  final geocoding = FakeGeocoding();
  final cloud = FakeCloudDispatch();
  final sync = FakeSync();
  final ai = FakeAi();
  final havens = FakeHavenService();
  final routing = FakeRouting();
  final secureStore = FakeSecureStore();
  final biometric = FakeBiometric();
  final nativeGuard = FakeNativeGuard();
  final voice = FakeVoice();
  final shake = FakeShakeSensor();
  final clock = FakeClock();

  /// Overrides for every provider in `lib/core/di/providers.dart`.
  List<Override> overrides() => [
        contactRepositoryProvider.overrideWithValue(contacts),
        incidentRepositoryProvider.overrideWithValue(incidents),
        settingsRepositoryProvider.overrideWithValue(settings),
        havenCacheRepositoryProvider.overrideWithValue(havenCache),
        safePlaceRepositoryProvider.overrideWithValue(safePlaces),
        chatRepositoryProvider.overrideWithValue(chat),
        locationServiceProvider.overrideWithValue(location),
        smsServiceProvider.overrideWithValue(sms),
        connectivityServiceProvider.overrideWithValue(connectivity),
        batteryServiceProvider.overrideWithValue(battery),
        hapticsServiceProvider.overrideWithValue(haptics),
        sirenServiceProvider.overrideWithValue(siren),
        strobeServiceProvider.overrideWithValue(strobe),
        audioEvidenceServiceProvider.overrideWithValue(audio),
        geocodingServiceProvider.overrideWithValue(geocoding),
        cloudDispatchServiceProvider.overrideWithValue(cloud),
        syncServiceProvider.overrideWithValue(sync),
        aiServiceProvider.overrideWithValue(ai),
        havenServiceProvider.overrideWithValue(havens),
        routingServiceProvider.overrideWithValue(routing),
        secureStoreProvider.overrideWithValue(secureStore),
        biometricServiceProvider.overrideWithValue(biometric),
        nativeGuardServiceProvider.overrideWithValue(nativeGuard),
        voiceTriggerServiceProvider.overrideWithValue(voice),
        shakeSensorServiceProvider.overrideWithValue(shake),
        clockProvider.overrideWithValue(clock),
      ];
}

/// Overrides for every provider, backed by [f] (or a fresh [Fakes]).
List<Override> fakeOverrides([Fakes? f]) => (f ?? Fakes()).overrides();
