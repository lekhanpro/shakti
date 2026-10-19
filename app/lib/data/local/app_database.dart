import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

export 'tables.dart';

part 'app_database.g.dart';

/// The single on-device SQLite database. Everything the SOS pipeline needs is
/// written here first; the network is always optional.
@DriftDatabase(
  tables: [Contacts, Incidents, Breadcrumbs, HavensCache, SafePlaces, ChatMessages, SyncQueue, Kv],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production database stored as `shakti.sqlite` in app documents.
  // coverage:ignore-start
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'shakti'));
  // coverage:ignore-end

  /// In-memory or temp-file database for tests.
  factory AppDatabase.forTesting(QueryExecutor e) => AppDatabase(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
