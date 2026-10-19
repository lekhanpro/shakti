import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import '../local/app_database.dart';
import 'mappers.dart';

class DriftContactRepository implements ContactRepository {
  DriftContactRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$ContactsTable, ContactRow> _ordered() => _db.select(_db.contacts)
    ..orderBy([(t) => OrderingTerm.asc(t.priority), (t) => OrderingTerm.asc(t.name)]);

  @override
  Stream<List<EmergencyContact>> watchAll() =>
      _ordered().watch().map((rows) => rows.map(contactFromRow).toList());

  @override
  Future<List<EmergencyContact>> active() async {
    final q = _ordered()..where((t) => t.isActive.equals(true));
    return (await q.get()).map(contactFromRow).toList();
  }

  @override
  Future<void> upsert(EmergencyContact c) => _db.into(_db.contacts).insertOnConflictUpdate(contactToRow(c));

  @override
  Future<void> delete(String id) => (_db.delete(_db.contacts)..where((t) => t.id.equals(id))).go();
}

class DriftIncidentRepository implements IncidentRepository {
  DriftIncidentRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<Incident>> watchAll() => (_db.select(_db.incidents)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch()
      .map((rows) => rows.map(incidentFromRow).toList());

  @override
  Future<Incident?> byId(String id) async {
    final row = await (_db.select(_db.incidents)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : incidentFromRow(row);
  }

  @override
  Future<Incident?> latestOpen() async {
    final q = _db.select(_db.incidents)
      ..where((t) => t.status.isIn([IncidentStatus.active.wire, IncidentStatus.countdown.wire]))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    final row = await q.getSingleOrNull();
    return row == null ? null : incidentFromRow(row);
  }

  @override
  Future<void> save(Incident i) => _db.into(_db.incidents).insertOnConflictUpdate(incidentToRow(i));

  @override
  Future<void> addBreadcrumb(Breadcrumb b) => _db.into(_db.breadcrumbs).insert(breadcrumbToRow(b));

  @override
  Future<List<Breadcrumb>> breadcrumbs(String incidentId) async {
    final q = _db.select(_db.breadcrumbs)
      ..where((t) => t.incidentId.equals(incidentId))
      ..orderBy([(t) => OrderingTerm.asc(t.recordedAt), (t) => OrderingTerm.asc(t.id)]);
    return (await q.get()).map(breadcrumbFromRow).toList();
  }
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  static const key = 'settings';

  static SafetySettings _decode(String? raw) {
    if (raw == null) return const SafetySettings();
    try {
      final j = jsonDecode(raw);
      return j is Map<String, Object?> ? SafetySettings.fromJson(j) : const SafetySettings();
    } on FormatException {
      return const SafetySettings();
    }
  }

  SimpleSelectStatement<$KvTable, KvRow> _query() =>
      _db.select(_db.kv)..where((t) => t.key.equals(key));

  @override
  Future<SafetySettings> load() async => _decode((await _query().getSingleOrNull())?.value);

  @override
  Future<void> save(SafetySettings s) => _db
      .into(_db.kv)
      .insertOnConflictUpdate(KvCompanion.insert(key: key, value: jsonEncode(s.toJson())));

  /// Drift query streams emit the current value on listen, then on change.
  @override
  Stream<SafetySettings> watch() => _query().watchSingleOrNull().map((r) => _decode(r?.value));
}

class DriftHavenCacheRepository implements HavenCacheRepository {
  DriftHavenCacheRepository(this._db, [this._clock = const SystemClock()]);
  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<List<SafeHaven>> cached() async =>
      (await (_db.select(_db.havensCache)..orderBy([(t) => OrderingTerm.asc(t.name)])).get())
          .map(havenFromRow)
          .toList();

  @override
  Future<void> replaceAll(List<SafeHaven> havens) => _db.transaction(() async {
        await _db.delete(_db.havensCache).go();
        final now = _clock.now();
        await _db.batch((b) {
          b.insertAllOnConflictUpdate(_db.havensCache, havens.map((h) => havenToRow(h, now)).toList());
        });
      });
}

class DriftSafePlaceRepository implements SafePlaceRepository {
  DriftSafePlaceRepository(this._db);
  final AppDatabase _db;

  SimpleSelectStatement<$SafePlacesTable, SafePlaceRow> _ordered() =>
      _db.select(_db.safePlaces)..orderBy([(t) => OrderingTerm.asc(t.name)]);

  @override
  Stream<List<SafePlace>> watchAll() => _ordered().watch().map((r) => r.map(safePlaceFromRow).toList());

  @override
  Future<List<SafePlace>> all() async => (await _ordered().get()).map(safePlaceFromRow).toList();

  @override
  Future<void> upsert(SafePlace p) => _db.into(_db.safePlaces).insertOnConflictUpdate(safePlaceToRow(p));

  @override
  Future<void> delete(String id) => (_db.delete(_db.safePlaces)..where((t) => t.id.equals(id))).go();
}

class DriftChatRepository implements ChatRepository {
  DriftChatRepository(this._db);
  final AppDatabase _db;

  @override
  Stream<List<ChatMessage>> watchAll() => (_db.select(_db.chatMessages)
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
      .watch()
      .map((r) => r.map(chatFromRow).toList());

  @override
  Future<void> add(ChatMessage m) => _db.into(_db.chatMessages).insertOnConflictUpdate(chatToRow(m));

  @override
  Future<void> clear() => _db.delete(_db.chatMessages).go();
}
