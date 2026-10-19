import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';
import '../local/app_database.dart';

/// The remote side of the sync queue. Kept tiny so tests can fake it.
abstract interface class RemoteSink {
  Future<void> upsertIncident(Map<String, Object?> row);
  Future<void> insertBreadcrumbs(List<Map<String, Object?>> rows);
}

/// Writes to Supabase `incident_reports` / `live_breadcrumbs`. RLS fills
/// `user_id` from the JWT.
// coverage:ignore-start
class SupabaseRemoteSink implements RemoteSink {
  SupabaseRemoteSink(this._client);
  final SupabaseClient _client;

  @override
  Future<void> upsertIncident(Map<String, Object?> row) =>
      _client.from('incident_reports').upsert(row, onConflict: 'id');

  @override
  Future<void> insertBreadcrumbs(List<Map<String, Object?>> rows) => _client
      .from('live_breadcrumbs')
      .upsert(rows, onConflict: 'incident_id,recorded_at', ignoreDuplicates: true);
}
// coverage:ignore-end

/// Used when no backend is configured: always throws, so queued items stay.
class NullRemoteSink implements RemoteSink {
  const NullRemoteSink();

  @override
  Future<void> upsertIncident(Map<String, Object?> row) =>
      Future.error(StateError('No backend configured'));

  @override
  Future<void> insertBreadcrumbs(List<Map<String, Object?>> rows) =>
      Future.error(StateError('No backend configured'));
}

/// Durable outbox in the `sync_queue` table, drained to [RemoteSink].
class SyncServiceImpl implements SyncService {
  SyncServiceImpl(this._db, this._remote, this._connectivity, this._clock);

  final AppDatabase _db;
  final RemoteSink _remote;
  final ConnectivityService _connectivity;
  final Clock _clock;

  static const entityIncident = 'incident';
  static const entityBreadcrumb = 'breadcrumb';
  static const breadcrumbBatch = 50;
  static const maxBackoff = Duration(seconds: 300);

  StreamSubscription<bool>? _sub;
  Future<int>? _inFlight;

  /// Backoff after the attempt number [attempts] failed: 2^attempts s, <= 300 s.
  static Duration backoff(int attempts) =>
      Duration(seconds: math.min(maxBackoff.inSeconds, math.pow(2, math.min(attempts, 16)).toInt()));

  /// Flushes whenever connectivity comes back online, and once now.
  void start() {
    _sub ??= _connectivity.onlineChanges.listen((online) {
      if (online) unawaited(flush());
    });
    unawaited(() async {
      try {
        if (await _connectivity.isOnline()) await flush();
      } catch (_) {
        // never surface sync failures
      }
    }());
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Future<void> enqueueIncident(Incident incident) async {
    final now = _clock.now();
    await _db.transaction(() async {
      await (_db.delete(_db.syncQueue)
            ..where((t) => t.entity.equals(entityIncident) & t.entityKey.equals(incident.id)))
          .go();
      await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
            entity: entityIncident,
            payload: jsonEncode(incident.toRemoteJson()),
            entityKey: Value(incident.id),
            nextAttemptAt: now,
            createdAt: now,
          ));
    });
  }

  @override
  Future<void> enqueueBreadcrumb(Breadcrumb b) async {
    final now = _clock.now();
    await _db.into(_db.syncQueue).insert(SyncQueueCompanion.insert(
          entity: entityBreadcrumb,
          payload: jsonEncode(b.toRemoteJson()),
          entityKey: Value(b.incidentId),
          nextAttemptAt: now,
          createdAt: now,
        ));
  }

  /// Single-flight: a concurrent call joins the running flush.
  @override
  Future<int> flush() => _inFlight ??= _flush().whenComplete(() => _inFlight = null);

  Future<int> _flush() async {
    final now = _clock.now();
    final due = await (_db.select(_db.syncQueue)
          ..where((t) => t.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt), (t) => OrderingTerm.asc(t.id)]))
        .get();
    if (due.isEmpty) return 0;

    var synced = 0;
    // Incidents first: breadcrumbs reference them via a foreign key.
    for (final row in due.where((r) => r.entity == entityIncident)) {
      try {
        await _remote.upsertIncident(_decode(row.payload));
        await _remove([row.id]);
        await _markIncidentSynced(row.entityKey);
        synced++;
      } catch (_) {
        await _fail([row]);
      }
    }

    final crumbs = due.where((r) => r.entity == entityBreadcrumb).toList();
    for (var i = 0; i < crumbs.length; i += breadcrumbBatch) {
      final chunk = crumbs.sublist(i, math.min(i + breadcrumbBatch, crumbs.length));
      try {
        await _remote.insertBreadcrumbs(chunk.map((r) => _decode(r.payload)).toList());
        await _remove(chunk.map((r) => r.id).toList());
        synced += chunk.length;
      } catch (_) {
        await _fail(chunk);
      }
    }

    // Unknown entities are dropped so they cannot block the queue forever.
    final unknown = due.where((r) => r.entity != entityIncident && r.entity != entityBreadcrumb);
    if (unknown.isNotEmpty) await _remove(unknown.map((r) => r.id).toList());
    return synced;
  }

  static Map<String, Object?> _decode(String payload) =>
      (jsonDecode(payload) as Map).cast<String, Object?>();

  Future<void> _remove(List<int> ids) => (_db.delete(_db.syncQueue)..where((t) => t.id.isIn(ids))).go();

  Future<void> _markIncidentSynced(String? id) async {
    if (id == null) return;
    // Only mark synced if no newer version was enqueued meanwhile.
    final pending = await (_db.select(_db.syncQueue)
          ..where((t) => t.entity.equals(entityIncident) & t.entityKey.equals(id)))
        .get();
    if (pending.isNotEmpty) return;
    await (_db.update(_db.incidents)..where((t) => t.id.equals(id)))
        .write(const IncidentsCompanion(synced: Value(true)));
  }

  Future<void> _fail(List<SyncQueueRow> rows) async {
    final now = _clock.now();
    await _db.batch((b) {
      for (final r in rows) {
        final attempts = r.attempts + 1;
        b.update(
          _db.syncQueue,
          SyncQueueCompanion(attempts: Value(attempts), nextAttemptAt: Value(now.add(backoff(attempts)))),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
  }
}
