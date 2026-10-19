import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../../../domain/engines/panic_state_machine.dart';
import '../../../domain/engines/sms_composer.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/services.dart';
import 'panic_view_state.dart';

/// Base URL of the guardian web tracker (`/track/<token>`).
const trackBaseUrl = String.fromEnvironment('TRACK_BASE_URL', defaultValue: 'https://shakti-track.vercel.app');

/// Per-channel budgets. The SMS is never gated on the network; location gets a
/// short budget so the SMS leaves well inside the 1.2 s latency target when a
/// fix is cached.
abstract final class PanicBudgets {
  static const location = Duration(seconds: 3);
  static const sms = Duration(seconds: 10);
  static const cloud = Duration(seconds: 10);
  static const geocode = Duration(seconds: 4);
  static const breadcrumbInterval = Duration(seconds: 10);
}

/// Orchestrates the emergency lifecycle described in spec section 4.
///
/// Every channel is isolated: a failure (no SIM, no permission, offline) is
/// recorded on the [DispatchReport] and never blocks the other channels.
class PanicController extends Notifier<PanicViewState> {
  final _machine = PanicStateMachine();
  Timer? _countdown;
  Timer? _breadcrumbs;
  StreamSubscription<bool>? _online;
  static const _uuid = Uuid();

  @override
  PanicViewState build() {
    ref.onDispose(_teardown);
    return const PanicViewState();
  }

  bool get _idleLike => _machine.state == PanicMachineState.idle || _machine.state == PanicMachineState.resolved;

  /// Starts an SOS. Covert triggers (decoy PIN) skip the countdown, the siren
  /// and haptics entirely.
  Future<void> trigger(TriggerSource source, {bool covert = false}) async {
    if (!_idleLike) return;
    final settings = await ref.read(settingsRepositoryProvider).load();
    final silent = covert || settings.stealthMode;

    if (covert) {
      if (!_machine.triggerImmediate()) return;
      state = PanicViewState(phase: PanicPhase.active, source: source, covert: true, startedAt: _now());
      await _dispatch(source, covert: true, silent: true);
      return;
    }

    if (!_machine.trigger()) return;
    final total = settings.countdownSeconds;
    state = PanicViewState(
      phase: PanicPhase.countdown,
      secondsLeft: total,
      totalSeconds: total,
      source: source,
      covert: false,
      startedAt: _now(),
    );
    if (!silent) unawaited(_safe(() => ref.read(hapticsServiceProvider).heavy()));

    final done = Completer<void>();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_machine.state != PanicMachineState.countdown) {
        t.cancel();
        if (!done.isCompleted) done.complete();
        return;
      }
      final left = state.secondsLeft - 1;
      if (left > 0) {
        state = state.copyWith(secondsLeft: left);
        if (!silent) unawaited(_safe(() => ref.read(hapticsServiceProvider).tick()));
        return;
      }
      t.cancel();
      _countdown = null;
      if (_machine.activate()) {
        state = state.copyWith(phase: PanicPhase.active, secondsLeft: 0);
        unawaited(_dispatch(source, covert: false, silent: silent).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }));
      } else if (!done.isCompleted) {
        done.complete();
      }
    });
    return done.future;
  }

  /// Cancels during the grace window. No message has left the device yet.
  void abort() {
    if (!_machine.abort()) return;
    _countdown?.cancel();
    _countdown = null;
    unawaited(_safe(() => ref.read(hapticsServiceProvider).cancel()));
    state = const PanicViewState();
  }

  /// Ends an active incident (user verified with PIN) and tells contacts.
  Future<void> resolve({bool falseAlarm = false}) async {
    if (!_machine.resolve()) return;
    _stopActiveChannels();
    final report = state.report;
    state = state.copyWith(phase: PanicPhase.resolved);
    if (report == null) return;

    final resolved = report.incident.copyWith(
      status: falseAlarm ? IncidentStatus.falseAlarm : IncidentStatus.resolved,
      resolvedAt: _now(),
      synced: false,
    );
    state = state.copyWith(report: report.withChannel(DispatchChannel.localSave, ChannelStatus.ok, incident: resolved));
    await _safe(() => ref.read(incidentRepositoryProvider).save(resolved));
    await _safe(() => ref.read(syncServiceProvider).enqueueIncident(resolved));

    if (resolved.covert) return;
    final settings = await ref.read(settingsRepositoryProvider).load();
    final name = _displayName(settings);
    final contacts = await _activeContacts();
    if (contacts.isNotEmpty) {
      await _safe(() => ref
          .read(smsServiceProvider)
          .sendToAll(contacts.map((c) => c.phone).toList(), SmsComposer.safe(userName: name, at: _now()))
          .timeout(PanicBudgets.sms));
    }
    if (settings.cloudEnabled) {
      await _safe(() => ref
          .read(cloudDispatchServiceProvider)
          .notifyResolved(resolved, userName: name, telegramChatId: _chatId(settings))
          .timeout(PanicBudgets.cloud));
    }
  }

  /// Returns to idle after the resolved summary has been seen.
  void acknowledge() {
    if (_machine.state != PanicMachineState.resolved) return;
    _machine.reset();
    state = const PanicViewState();
  }

  /// Restores an incident that was active when the app was killed.
  Future<void> restore() async {
    if (!_idleLike) return;
    final open = await ref.read(incidentRepositoryProvider).latestOpen();
    if (open == null || open.status != IncidentStatus.active) return;
    if (!_machine.triggerImmediate()) return;
    state = PanicViewState(
      phase: PanicPhase.active,
      source: open.source,
      covert: open.covert,
      startedAt: open.createdAt,
      report: DispatchReport(incident: open, channels: {
        DispatchChannel.localSave: ChannelStatus.ok,
        DispatchChannel.sms: open.smsDispatched ? ChannelStatus.ok : ChannelStatus.skipped,
        DispatchChannel.cloud: open.cloudDispatched ? ChannelStatus.ok : ChannelStatus.pending,
      }),
    );
    _startBreadcrumbs(open.id);
    final settings = await ref.read(settingsRepositoryProvider).load();
    if (!ref.mounted) return;
    _watchConnectivity(open.id, _displayName(settings), settings);
    if (!open.cloudDispatched) {
      unawaited(_sendCloud(open, _displayName(settings), settings));
    }
  }

  // ---------------------------------------------------------------------------
  // Pipeline
  // ---------------------------------------------------------------------------

  Future<void> _dispatch(TriggerSource source, {required bool covert, required bool silent}) async {
    final settings = await ref.read(settingsRepositoryProvider).load();
    final name = _displayName(settings);
    final incidents = ref.read(incidentRepositoryProvider);

    // 1. Local save first: the incident exists even if every channel fails.
    var incident = Incident(
      id: _uuid.v4(),
      source: source,
      status: IncidentStatus.active,
      createdAt: _now(),
      shareToken: _shareToken(),
      covert: covert,
    );
    _update(DispatchReport(incident: incident, channels: {
      for (final c in DispatchChannel.values) c: ChannelStatus.pending,
    }).withChannel(DispatchChannel.localSave, ChannelStatus.running));
    final saved = await _safe(() => incidents.save(incident));
    _setChannel(DispatchChannel.localSave, saved ? ChannelStatus.ok : ChannelStatus.failed,
        note: saved ? null : 'Device storage failed; alert channels will still run');

    // 2. Location (bounded) + battery, in parallel.
    _setChannel(DispatchChannel.location, ChannelStatus.running);
    final fixFuture = _guard<Result<LocationFix>>(
      () => ref.read(locationServiceProvider).currentFix(timeout: PanicBudgets.location),
      const Err('Location unavailable'),
      PanicBudgets.location + const Duration(milliseconds: 500),
    );
    final batteryFuture = _guard<int?>(() => ref.read(batteryServiceProvider).level(), null, const Duration(seconds: 1));
    final location = ref.read(locationServiceProvider);
    final cached = location is CachedLocationService ? (location as CachedLocationService).cachedFix : null;
    // Only a recent, already available fix may accompany the immediate SMS.
    final cachedAge = cached == null ? null : _now().difference(cached.at);
    final usable = cachedAge != null && !cachedAge.isNegative && cachedAge <= const Duration(minutes: 2) ? cached : null;
    incident = incident.copyWith(lat: usable?.point.lat, lng: usable?.point.lng);
    _setChannel(DispatchChannel.location, ChannelStatus.running, incident: incident);

    // 3. Fan out. Each channel is independent.
    final trackUrl = '$trackBaseUrl/track/${incident.shareToken}';
    final dispatch = Future.wait([
      _sendSms(incident, name, usable?.point, null, trackUrl),
      _startAudio(incident, enabled: settings.recordAudio),
      _startSiren(enabled: settings.sirenOnSos && !silent),
      _sendCloud(incident, name, settings),
    ]);

    _startBreadcrumbs(incident.id);
    _watchConnectivity(incident.id, name, settings);
    final fix = (await fixFuture).valueOrNull;
    final battery = await batteryFuture;
    final enriched = (state.report?.incident ?? incident).copyWith(
        lat: fix?.point.lat ?? usable?.point.lat,
        lng: fix?.point.lng ?? usable?.point.lng, batteryLevel: battery);
    _setChannel(DispatchChannel.location,
        fix == null && usable == null ? ChannelStatus.failed : ChannelStatus.ok,
        note: fix == null && usable == null ? 'Location unavailable; SMS was not delayed' : null,
        incident: enriched);
    await dispatch;

    // 4. Persist the final channel state, then keep streaming breadcrumbs.
    final latest = state.report?.incident ?? incident;
    await _safe(() => incidents.save(latest));
    await _safe(() => ref.read(syncServiceProvider).enqueueIncident(latest));
    if (fix != null) {
      await _recordBreadcrumb(latest.id, fix, battery);
    }
    if (_machine.state == PanicMachineState.active) {
      unawaited(_resolveAddress(fix?.point));
    }
  }

  Future<void> _sendSms(Incident incident, String name, GeoPoint? at, int? battery, String trackUrl) async {
    _setChannel(DispatchChannel.sms, ChannelStatus.running);
    final contacts = await _activeContacts();
    if (contacts.isEmpty) {
      _setChannel(DispatchChannel.sms, ChannelStatus.failed, note: 'No trusted contacts added');
      return;
    }
    final message = SmsComposer.sos(
      userName: name,
      location: at,
      address: incident.address,
      battery: battery,
      trackUrl: trackUrl,
      at: incident.createdAt,
    );
    final result = await _guard<Result<int>>(
      () => ref.read(smsServiceProvider).sendToAll(contacts.map((c) => c.phone).toList(), message),
      const Err('SMS timed out'),
      PanicBudgets.sms,
    );
    result.when(
      ok: (sent) {
        final updated = (state.report?.incident ?? incident).copyWith(smsDispatched: sent > 0);
        _setChannel(
          DispatchChannel.sms,
          sent > 0 ? ChannelStatus.ok : ChannelStatus.failed,
          note: sent > 0 ? 'Android accepted $sent of ${contacts.length}; delivery unconfirmed' : 'SMS handoff failed',
          incident: updated,
          smsRecipients: sent,
        );
      },
      err: (m) => _setChannel(DispatchChannel.sms, ChannelStatus.failed, note: m),
    );
  }

  Future<void> _startAudio(Incident incident, {required bool enabled}) async {
    if (!enabled) {
      _setChannel(DispatchChannel.audio, ChannelStatus.skipped, note: 'Off in settings');
      return;
    }
    _setChannel(DispatchChannel.audio, ChannelStatus.running, note: 'Recording 60 s');
    // Recording runs for a minute; don't hold the pipeline for it.
    unawaited(() async {
      final r = await _guard<Result<String>>(
        () => ref.read(audioEvidenceServiceProvider).record(incident.id),
        const Err('Recorder unavailable'),
        const Duration(seconds: 75),
      );
      if (!ref.mounted || state.report?.incident.id != incident.id) return;
      r.when(
        ok: (path) {
          final updated = (state.report?.incident ?? incident).copyWith(audioPath: path);
          _setChannel(DispatchChannel.audio, ChannelStatus.ok, note: 'Encrypted and saved', incident: updated);
          unawaited(_safe(() => ref.read(incidentRepositoryProvider).save(updated)));
        },
        err: (m) => _setChannel(DispatchChannel.audio, ChannelStatus.failed, note: m),
      );
    }());
  }

  Future<void> _startSiren({required bool enabled}) async {
    if (!enabled) {
      _setChannel(DispatchChannel.siren, ChannelStatus.skipped, note: 'Silent mode');
      return;
    }
    final ok = await _safe(() => ref.read(sirenServiceProvider).start());
    unawaited(_safe(() => ref.read(hapticsServiceProvider).sosPattern()));
    _setChannel(DispatchChannel.siren, ok ? ChannelStatus.ok : ChannelStatus.failed);
  }

  Future<void> _sendCloud(Incident incident, String name, SafetySettings settings) async {
    if (!settings.cloudEnabled) {
      _setChannel(DispatchChannel.cloud, ChannelStatus.skipped, note: 'Cloud alerts off');
      return;
    }
    _setChannel(DispatchChannel.cloud, ChannelStatus.running);
    final online = await _guard<bool>(() => ref.read(connectivityServiceProvider).isOnline(), false, const Duration(seconds: 1));
    if (!online) {
      _setChannel(DispatchChannel.cloud, ChannelStatus.pending, note: 'Offline. Will send when back online');
      return;
    }
    await _cloudAttempt(incident, name, settings);
  }

  Future<void> _cloudAttempt(Incident incident, String name, SafetySettings settings) async {
    final current = state.report?.incident ?? incident;
    final r = await _guard<Result<void>>(
      () => ref.read(cloudDispatchServiceProvider).dispatch(current, userName: name, telegramChatId: _chatId(settings)),
      const Err('Cloud timed out'),
      PanicBudgets.cloud,
    );
    if (!ref.mounted || state.report?.incident.id != incident.id) return;
    r.when(
      ok: (_) => _setChannel(
        DispatchChannel.cloud,
        ChannelStatus.ok,
        note: 'Guardian alert acknowledged by backend',
        incident: (state.report?.incident ?? current).copyWith(cloudDispatched: true),
      ),
      err: (m) => _setChannel(DispatchChannel.cloud, ChannelStatus.failed, note: m),
    );
  }

  /// Retries the cloud alert once connectivity returns during an active SOS.
  void _watchConnectivity(String incidentId, String name, SafetySettings settings) {
    if (!settings.cloudEnabled) return;
    _online?.cancel();
    _online = ref.read(connectivityServiceProvider).onlineChanges.listen((online) {
      final report = state.report;
      if (!online || report == null || report.incident.id != incidentId) return;
      if (report.status(DispatchChannel.cloud) == ChannelStatus.ok) return;
      unawaited(_cloudAttempt(report.incident, name, settings));
      unawaited(_safe(() => ref.read(syncServiceProvider).flush()));
    });
  }

  void _startBreadcrumbs(String incidentId) {
    _breadcrumbs?.cancel();
    _setChannel(DispatchChannel.tracking, ChannelStatus.ok, note: 'Every 10 s');
    _breadcrumbs = Timer.periodic(PanicBudgets.breadcrumbInterval, (_) async {
      if (_machine.state != PanicMachineState.active) return;
      final fix = (await _guard<Result<LocationFix>>(
        () => ref.read(locationServiceProvider).currentFix(timeout: PanicBudgets.location),
        const Err('timeout'),
        PanicBudgets.location + const Duration(seconds: 1),
      ))
          .valueOrNull;
      if (fix == null || !ref.mounted) return;
      final battery = await _guard<int?>(() => ref.read(batteryServiceProvider).level(), null, const Duration(seconds: 1));
      await _recordBreadcrumb(incidentId, fix, battery);
    });
  }

  Future<void> _recordBreadcrumb(String incidentId, LocationFix fix, int? battery) async {
    final b = Breadcrumb(
      incidentId: incidentId,
      lat: fix.point.lat,
      lng: fix.point.lng,
      recordedAt: fix.at,
      speedKmh: fix.speedKmh,
      accuracyM: fix.accuracyM,
      battery: battery,
    );
    await _safe(() => ref.read(incidentRepositoryProvider).addBreadcrumb(b));
    await _safe(() => ref.read(syncServiceProvider).enqueueBreadcrumb(b));
  }

  Future<void> _resolveAddress(GeoPoint? at) async {
    if (at == null) return;
    final address = await _guard<String?>(() => ref.read(geocodingServiceProvider).reverse(at), null, PanicBudgets.geocode);
    final report = state.report;
    if (address == null || report == null || !ref.mounted) return;
    final updated = report.incident.copyWith(address: address, synced: false);
    _update(report.withChannel(DispatchChannel.location, ChannelStatus.ok, incident: updated, note: address));
    await _safe(() => ref.read(incidentRepositoryProvider).save(updated));
    await _safe(() => ref.read(syncServiceProvider).enqueueIncident(updated));
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<EmergencyContact>> _activeContacts() =>
      _guard(() => ref.read(contactRepositoryProvider).active(), const <EmergencyContact>[], const Duration(seconds: 2));

  void _update(DispatchReport report) {
    if (!ref.mounted) return;
    state = state.copyWith(report: report);
  }

  void _setChannel(DispatchChannel c, ChannelStatus s, {String? note, Incident? incident, int? smsRecipients}) {
    final report = state.report;
    if (report == null) return;
    _update(report.withChannel(c, s, note: note, incident: incident, smsRecipients: smsRecipients));
  }

  void _stopActiveChannels() {
    _breadcrumbs?.cancel();
    _breadcrumbs = null;
    _online?.cancel();
    _online = null;
    unawaited(_safe(() => ref.read(sirenServiceProvider).stop()));
    unawaited(_safe(() => ref.read(strobeServiceProvider).stop()));
    unawaited(_safe(() => ref.read(hapticsServiceProvider).cancel()));
    unawaited(_safe(() => ref.read(audioEvidenceServiceProvider).stop()));
  }

  void _teardown() {
    _countdown?.cancel();
    _breadcrumbs?.cancel();
    _online?.cancel();
  }

  DateTime _now() => ref.read(clockProvider).now();

  static String _displayName(SafetySettings s) => s.userName.trim().isEmpty ? 'A Shakti user' : s.userName.trim();

  static String? _chatId(SafetySettings s) => s.telegramChatId.trim().isEmpty ? null : s.telegramChatId.trim();

  /// 24 URL-safe characters (~143 bits) from a CSPRNG.
  static String _shareToken() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final rnd = Random.secure();
    return List.generate(24, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }

  /// Runs [f]; returns false instead of throwing.
  static Future<bool> _safe(Future<void> Function() f) async {
    try {
      await f();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Runs [f] with a hard [timeout]; any error or timeout yields [fallback].
  static Future<T> _guard<T>(Future<T> Function() f, T fallback, Duration timeout) async {
    try {
      return await f().timeout(timeout);
    } catch (_) {
      return fallback;
    }
  }
}

final panicControllerProvider = NotifierProvider<PanicController, PanicViewState>(PanicController.new);
