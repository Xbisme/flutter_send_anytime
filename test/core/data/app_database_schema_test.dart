import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/data/database/app_database.dart';

/// Schema guard (#006, Constitution IX). Pins the current schema version and
/// confirms `onCreate` builds every table. When the schema changes, bump the
/// version here and add a migration test covering the prior version.
void main() {
  test('schema is version 1 and onCreate builds all tables', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 1);

    // Both tables exist and are queryable (createAll ran via onCreate).
    expect(await db.select(db.transferRecords).get(), isEmpty);
    expect(await db.select(db.transferRecordFiles).get(), isEmpty);
  });
}
