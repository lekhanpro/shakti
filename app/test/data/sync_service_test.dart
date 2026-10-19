import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/data/local/app_database.dart';
import 'package:shakti/data/repositories/drift_repositories.dart';
import 'package:shakti/data/services/sync_service_impl.dart';
import 'package:shakti/domain/entities/entities.dart';

import '../fakes/fakes.dart';

class FakeRemote implements RemoteSink {
  final incidents = <Map<String, Object?>>[];
  final batches = <List<Map<String, Object?>>>[];
  bool fail = false;
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<void> upsertIncident(Map<String, Object?> row) async {
    calls++;
    final g = gate;
    if (g != null) await g.future;
    if (fail) throw Exception('offline');
    incidents.add(row);
  }

  @override
  Future<void> insertBreadcrumbs(List<Map<String, Object?>> rows) async {
    calls++;
    if (fail) throw Exception('offline');
    batches.add(rows);
  }
}

Incident _incident(String id, {IncidentStatus status = IncidentStatus.active}) => Incident(
      id: id,
      source: TriggerSource.hudTap,
      status: status,
      createdAt: DateTime.utc(2026, 9, 29, 10),
      shareToken: 'abcdefghijklmnopqrstuvwxyz',
    );

Breadcrumb _crumb(int i) =>
    Breadcrumb(incidentId: 'i1', lat: 12, lng: 77, recordedAt: DateTime.utc(2026, 9, 29, 10, 0, i));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FakeRemote remote;
  late FakeConnectivity net;
  late FakeClock clock;
  late SyncServiceImpl sync;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    remote = FakeRemote();
    net = FakeConnectivity(online: false);
    clock = FakeClock(DateTime(2026, 9, 29, 10));
    sync = SyncServiceImpl(db, remote, net, clock);
  });
  tearDown(() async {
    await sync.dispose();
    await db.close();
  });

  Future<List<SyncQueueRow>> queue() => db.select(db.syncQueue).get();

  test('backoff is 2^attempts seconds capped at 300', () {
    expect(SyncServiceImpl.backoff(1), const Duration(seconds: 2));
    expect(SyncServiceImpl.backoff(3), const Duration(seconds: 8));
    expect(SyncServiceImpl.backoff(8), const Duration(seconds: 256));
    expect(SyncServiceImpl.backoff(9), const Duration(seconds: 300));
    expect(SyncServiceImpl.backoff(100), const Duration(seconds: 300));
  });

  test('re-enqueueing an incident replaces the pending entry', () async {
    await sync.enqueueIncident(_incident('i1'));
    await sync.enqueueIncident(_incident('i2'));
    await sync.enqueueIncident(_incident('i1', status: IncidentStatus.resolved));
    final q = await queue();
    expect(q, hasLength(2));
    expect(q.where((r) => r.entityKey == 'i1').single.payload, contains('RESOLVED'));
  });

  test('flush sends incidents then breadcrumbs in batches of 50 and marks synced', () async {
    final repo = DriftIncidentRepository(db);
    await repo.save(_incident('i1'));
    for (var i = 0; i < 55; i++) {
      await sync.enqueueBreadcrumb(_crumb(i));
    }
    await sync.enqueueIncident(_incident('i1'));

    expect(await sync.flush(), 56);
    expect(remote.incidents.single['id'], 'i1');
    expect(remote.incidents.single['trigger_source'], 'HUD_TAP');
    expect(remote.batches.map((b) => b.length), [50, 5]);
    expect(remote.batches.first.first['incident_id'], 'i1');
    expect(await queue(), isEmpty);
    expect((await repo.byId('i1'))!.synced, isTrue);
    expect(await sync.flush(), 0);
  });

  test('failure keeps items and applies exponential backoff', () async {
    remote.fail = true;
    await sync.enqueueIncident(_incident('i1'));
    await sync.enqueueBreadcrumb(_crumb(1));

    expect(await sync.flush(), 0);
    var q = await queue();
    expect(q.map((r) => r.attempts), everyElement(1));
    expect(q.first.nextAttemptAt, clock.now().add(const Duration(seconds: 2)));

    // Not due yet: nothing is attempted.
    remote.calls = 0;
    expect(await sync.flush(), 0);
    expect(remote.calls, 0);

    clock.advance(const Duration(seconds: 2));
    expect(await sync.flush(), 0);
    q = await queue();
    expect(q.map((r) => r.attempts), everyElement(2));
    expect(q.first.nextAttemptAt, clock.now().add(const Duration(seconds: 4)));

    remote.fail = false;
    clock.advance(const Duration(seconds: 4));
    expect(await sync.flush(), 2);
    expect(await queue(), isEmpty);
  });

  test('concurrent flushes share one run', () async {
    await sync.enqueueIncident(_incident('i1'));
    remote.gate = Completer<void>();
    final a = sync.flush();
    final b = sync.flush();
    await pumpEventQueue();
    remote.gate!.complete();
    expect(await a, 1);
    expect(await b, 1);
    expect(remote.incidents, hasLength(1));
  });

  test('start flushes when connectivity comes online', () async {
    await sync.enqueueIncident(_incident('i1'));
    sync.start();
    await pumpEventQueue();
    expect(remote.incidents, isEmpty); // offline at start

    net.set(true);
    await pumpEventQueue();
    await sync.flush(); // joins or re-runs; either way the queue is drained
    expect(remote.incidents, hasLength(1));
    expect(await queue(), isEmpty);

    await sync.dispose();
    await sync.enqueueIncident(_incident('i2'));
    net.set(true);
    await pumpEventQueue();
    expect(remote.incidents, hasLength(1)); // disposed: no auto flush
  });

  test('start flushes immediately when already online', () async {
    net.online = true;
    await sync.enqueueIncident(_incident('i1'));
    sync.start();
    await pumpEventQueue(times: 50);
    expect(remote.incidents, hasLength(1));
  });

  test('NullRemoteSink retains items', () async {
    final offline = SyncServiceImpl(db, const NullRemoteSink(), net, clock);
    await offline.enqueueIncident(_incident('i1'));
    await offline.enqueueBreadcrumb(_crumb(1));
    expect(await offline.flush(), 0);
    expect(await queue(), hasLength(2));
  });

  test('unknown entities are dropped', () async {
    await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
        entity: 'mystery', payload: '{}', nextAttemptAt: clock.now(), createdAt: clock.now()));
    expect(await sync.flush(), 0);
    expect(await queue(), isEmpty);
  });
}
