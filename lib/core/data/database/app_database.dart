import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:safe_send/core/data/daos/transfer_history_dao.dart';
import 'package:safe_send/core/data/database/tables/transfer_record_files_table.dart';
import 'package:safe_send/core/data/database/tables/transfer_records_table.dart';

part 'app_database.g.dart';

/// The app's local SQLite database (#006 — transfer history only; Constitution
/// IX names drift for history persistence). `drift_flutter`'s [driftDatabase]
/// resolves the on-device file path, bundles the native sqlite3 libs, and runs
/// queries on a background isolate. Tests pass an in-memory executor.
@DriftDatabase(
  tables: [TransferRecords, TransferRecordFiles],
  daos: [TransferHistoryDao],
)
class AppDatabase extends _$AppDatabase {
  /// Open the on-device database. Pass [executor] in tests
  /// (`NativeDatabase.memory()`).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'safe_send'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Enable FK enforcement so child file rows cascade-delete with a record.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
