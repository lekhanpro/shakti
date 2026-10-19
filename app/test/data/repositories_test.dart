import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakti/data/local/app_database.dart';
import 'package:shakti/data/repositories/drift_repositories.dart';
import 'package:shakti/domain/entities/entities.dart';

import '../fakes/fakes.dart';

Incident _incident(String id, DateTime at, {IncidentStatus status = IncidentStatus.active}) => Incident(
      id: id,
      source: TriggerSource.triplePower,
      status: status,
      createdAt: at,
      shareToken: 'tok_${id}_abcdefghijklmnopqrstu',
    );

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('DriftContactRepository', () {
    test('upsert, active ordered by priority, delete, watch', () async {
      final repo = DriftContactRepository(db);
      await repo.upsert(const EmergencyContact(id: 'a', name: 'Asha', phone: '+911', priority: 3));
      await repo.upsert(const EmergencyContact(id: 'b', name: 'Bina', phone: '+912', priority: 1));
      await repo.upsert(const EmergencyContact(id: 'c', name: 'Chitra', phone: '+913', priority: 2, isActive: false));

      expect((await repo.active()).map((c) => c.id), ['b', 'a']);

      await repo.upsert(const EmergencyContact(
          id: 'a', name: 'Asha K', phone: '+911', relationship: 'Friend', priority: 1));
      final active = await repo.active();
      expect(active.map((c) => c.id), ['a', 'b']); // tie on priority, name asc
      expect(active.first.relationship, 'Friend');
      expect(active.first.name, 'Asha K');

      await repo.delete('b');
      final all = await repo.watchAll().first;
      expect(all.map((c) => c.id), ['a', 'c']);
      expect(all.last.isActive, isFalse);
    });
  });

  group('DriftIncidentRepository', () {
    test('save is an upsert and round-trips every field', () async {
      final repo = DriftIncidentRepository(db);
      final t = DateTime(2026, 9, 29, 10);
      final full = Incident(
        id: 'i1',
        source: TriggerSource.decoyPin,
        status: IncidentStatus.countdown,
        createdAt: t,
        shareToken: 'abcdefghijklmnopqrstuvwxyz',
        lat: 12.9,
        lng: 77.6,
        address: 'MG Road',
        batteryLevel: 42,
        smsDispatched: true,
        cloudDispatched: true,
        audioPath: '/x.enc',
        resolvedAt: t.add(const Duration(minutes: 5)),
        covert: true,
        synced: true,
      );
      await repo.save(full);
      final back = (await repo.byId('i1'))!;
      expect(back, full);
      expect(back.source, TriggerSource.decoyPin);
      expect(back.shareToken, full.shareToken);
      expect(back.batteryLevel, 42);
      expect(back.covert, isTrue);

      await repo.save(full.copyWith(status: IncidentStatus.resolved));
      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
      expect(all.single.status, IncidentStatus.resolved);
      expect(await repo.byId('missing'), isNull);
    });

    test('latestOpen returns the newest ACTIVE or COUNTDOWN incident', () async {
      final repo = DriftIncidentRepository(db);
      final t = DateTime(2026, 9, 29, 10);
      expect(await repo.latestOpen(), isNull);
      await repo.save(_incident('old', t));
      await repo.save(_incident('mid', t.add(const Duration(minutes: 1)), status: IncidentStatus.countdown));
      await repo.save(_incident('new', t.add(const Duration(minutes: 2)), status: IncidentStatus.resolved));
      await repo.save(_incident('fa', t.add(const Duration(minutes: 3)), status: IncidentStatus.falseAlarm));
      expect((await repo.latestOpen())!.id, 'mid');
      expect((await repo.watchAll().first).map((i) => i.id), ['fa', 'new', 'mid', 'old']);
    });

    test('breadcrumbs are stored per incident in time order', () async {
      final repo = DriftIncidentRepository(db);
      final t = DateTime(2026, 9, 29, 10);
      await repo.addBreadcrumb(Breadcrumb(
          incidentId: 'i1', lat: 1, lng: 2, recordedAt: t.add(const Duration(seconds: 10)), speedKmh: 4, accuracyM: 5, battery: 60));
      await repo.addBreadcrumb(Breadcrumb(incidentId: 'i1', lat: 3, lng: 4, recordedAt: t));
      await repo.addBreadcrumb(Breadcrumb(incidentId: 'i2', lat: 9, lng: 9, recordedAt: t));
      final crumbs = await repo.breadcrumbs('i1');
      expect(crumbs.map((b) => b.lat), [3, 1]);
      expect(crumbs.last.speedKmh, 4);
      expect(crumbs.last.accuracyM, 5);
      expect(crumbs.last.battery, 60);
    });

    test('latestOpen survives closing and reopening a file database', () async {
      final dir = await Directory.systemTemp.createTemp('shakti_db');
      final file = File('${dir.path}${Platform.pathSeparator}shakti.sqlite');
      try {
        var fileDb = AppDatabase.forTesting(NativeDatabase(file));
        await DriftIncidentRepository(fileDb).save(_incident('persist', DateTime(2026, 9, 29)));
        await fileDb.close();

        fileDb = AppDatabase.forTesting(NativeDatabase(file));
        final open = await DriftIncidentRepository(fileDb).latestOpen();
        expect(open?.id, 'persist');
        expect(open?.status, IncidentStatus.active);
        await fileDb.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('DriftSettingsRepository', () {
    test('load defaults, save, watch emits current value first', () async {
      final repo = DriftSettingsRepository(db);
      expect((await repo.load()).countdownSeconds, 5);

      final emitted = <SafetySettings>[];
      final sub = repo.watch().listen(emitted.add);
      await pumpEventQueue();
      expect(emitted, hasLength(1));
      expect(emitted.first.userName, '');

      await repo.save(const SafetySettings(userName: 'Priya', countdownSeconds: 10, voicePhrases: ['bachao']));
      await pumpEventQueue();
      expect(emitted.last.userName, 'Priya');
      expect((await repo.load()).countdownSeconds, 10);
      expect((await repo.load()).voicePhrases, ['bachao']);
      expect((await repo.watch().first).userName, 'Priya');
      await sub.cancel();
    });

    test('corrupt JSON falls back to defaults', () async {
      await db.into(db.kv).insert(KvCompanion.insert(key: 'settings', value: 'not json{'));
      expect((await DriftSettingsRepository(db).load()).sirenOnSos, isTrue);
      await db.into(db.kv).insertOnConflictUpdate(KvCompanion.insert(key: 'settings', value: '[1,2]'));
      expect((await DriftSettingsRepository(db).load()).countdownSeconds, 5);
    });
  });

  group('DriftHavenCacheRepository', () {
    test('replaceAll swaps the whole cache', () async {
      final repo = DriftHavenCacheRepository(db, FakeClock());
      await repo.replaceAll(const [
        SafeHaven(id: 'osm:node/1', name: 'Zeta Police', category: HavenCategory.police, point: GeoPoint(1, 2), phone: '100', open24h: true),
        SafeHaven(id: 'osm:way/2', name: 'Alpha Hospital', category: HavenCategory.hospital, point: GeoPoint(3, 4), address: 'Main St'),
      ]);
      var cached = await repo.cached();
      expect(cached.map((h) => h.name), ['Alpha Hospital', 'Zeta Police']);
      expect(cached.last.phone, '100');
      expect(cached.last.open24h, isTrue);
      expect(cached.first.category, HavenCategory.hospital);
      expect(cached.first.address, 'Main St');
      expect(cached.first.point, const GeoPoint(3, 4));

      await repo.replaceAll(const [
        SafeHaven(id: 'osm:node/9', name: 'Night Pharmacy', category: HavenCategory.pharmacy, point: GeoPoint(5, 6)),
      ]);
      cached = await repo.cached();
      expect(cached.single.id, 'osm:node/9');
    });
  });

  group('DriftSafePlaceRepository', () {
    test('upsert, all, watchAll, delete', () async {
      final repo = DriftSafePlaceRepository(db);
      await repo.upsert(const SafePlace(id: 'h', name: 'Home', point: GeoPoint(1, 2)));
      await repo.upsert(const SafePlace(id: 'c', name: 'College', point: GeoPoint(3, 4), radiusM: 300));
      await repo.upsert(const SafePlace(id: 'h', name: 'Home', point: GeoPoint(1, 2.5), radiusM: 200));
      final all = await repo.all();
      expect(all.map((p) => p.name), ['College', 'Home']);
      expect(all.last.radiusM, 200);
      expect(all.last.point.lng, 2.5);
      await repo.delete('c');
      expect((await repo.watchAll().first).single.id, 'h');
    });
  });

  group('DriftChatRepository', () {
    test('add keeps chronological order, clear empties', () async {
      final repo = DriftChatRepository(db);
      final t = DateTime(2026, 9, 29);
      await repo.add(ChatMessage(id: '2', role: ChatRole.assistant, content: 'Hi', createdAt: t.add(const Duration(seconds: 1))));
      await repo.add(ChatMessage(id: '1', role: ChatRole.user, content: 'Hello', createdAt: t));
      final msgs = await repo.watchAll().first;
      expect(msgs.map((m) => m.id), ['1', '2']);
      expect(msgs.first.role, ChatRole.user);
      await repo.clear();
      expect(await repo.watchAll().first, isEmpty);
    });
  });
}
