import 'package:drift/drift.dart';

/// Drift table definitions. Row classes carry a `Row` suffix so they never
/// clash with the domain entities of the same name.

@DataClassName('ContactRow')
class Contacts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get relationship => text().withDefault(const Constant('Family'))();
  IntColumn get priority => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('IncidentRow')
@TableIndex(name: 'idx_incidents_created_at', columns: {#createdAt})
class Incidents extends Table {
  TextColumn get id => text()();
  TextColumn get source => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get shareToken => text()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  TextColumn get address => text().nullable()();
  IntColumn get batteryLevel => integer().nullable()();
  BoolColumn get smsDispatched => boolean().withDefault(const Constant(false))();
  BoolColumn get cloudDispatched => boolean().withDefault(const Constant(false))();
  TextColumn get audioPath => text().nullable()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();
  BoolColumn get covert => boolean().withDefault(const Constant(false))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BreadcrumbRow')
@TableIndex(name: 'idx_breadcrumbs_incident_id', columns: {#incidentId})
class Breadcrumbs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get incidentId => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get speed => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  IntColumn get battery => integer().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DataClassName('HavenCacheRow')
class HavensCache extends Table {
  @override
  String get tableName => 'havens_cache';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get open24h => boolean().withDefault(const Constant(false))();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SafePlaceRow')
class SafePlaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get radiusM => real().withDefault(const Constant(150))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ChatMessageRow')
class ChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncQueueRow')
class SyncQueue extends Table {
  @override
  String get tableName => 'sync_queue';

  IntColumn get id => integer().autoIncrement()();

  /// `incident` or `breadcrumb`.
  TextColumn get entity => text()();

  /// Remote row as JSON.
  TextColumn get payload => text()();

  /// For incidents: the incident id, so a newer enqueue replaces the old one.
  TextColumn get entityKey => text().nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('KvRow')
class Kv extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
