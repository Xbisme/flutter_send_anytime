import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/data/database/app_database.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

/// Foundational DAO round-trip over an in-memory drift database (no device).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  TransferRecordsCompanion record(
    String id, {
    TransferDirection direction = TransferDirection.sent,
    DateTime? at,
    String peerLabel = '',
  }) {
    return TransferRecordsCompanion.insert(
      id: id,
      direction: direction.name,
      status: 'completed',
      pairingMethod: 'sixDigitCode',
      peerLabel: Value(peerLabel),
      fileCount: 1,
      totalBytes: 100,
      createdAt: at ?? DateTime(2026, 6, 25, 10),
    );
  }

  TransferRecordFilesCompanion file(String recordId, String name) =>
      TransferRecordFilesCompanion.insert(
        recordId: recordId,
        name: name,
        size: 100,
        position: 0,
      );

  test('insert then watchAll returns the record with its files', () async {
    await db.transferHistoryDao.insertRecord(record('a'), [file('a', 'x.pdf')]);
    final rows = await db.transferHistoryDao.watchAll(HistoryFilter.none).first;
    expect(rows, hasLength(1));
    expect(rows.first.record.id, 'a');
    expect(rows.first.files.single.name, 'x.pdf');
  });

  test('watchAll orders newest-first', () async {
    await db.transferHistoryDao.insertRecord(
      record('old', at: DateTime(2026, 6, 20)),
      const [],
    );
    await db.transferHistoryDao.insertRecord(
      record('new', at: DateTime(2026, 6, 25)),
      const [],
    );
    final rows = await db.transferHistoryDao.watchAll(HistoryFilter.none).first;
    expect(rows.map((r) => r.record.id).toList(), ['new', 'old']);
  });

  test('watchAll filters by direction', () async {
    await db.transferHistoryDao.insertRecord(record('s'), const []);
    await db.transferHistoryDao.insertRecord(
      record('r', direction: TransferDirection.received),
      const [],
    );
    final rows = await db.transferHistoryDao
        .watchAll(const HistoryFilter(direction: TransferDirection.received))
        .first;
    expect(rows.map((r) => r.record.id), ['r']);
  });

  test('watchAll filters by date range', () async {
    await db.transferHistoryDao.insertRecord(
      record('jan', at: DateTime(2026)),
      const [],
    );
    await db.transferHistoryDao.insertRecord(
      record('jun', at: DateTime(2026, 6, 25)),
      const [],
    );
    final rows = await db.transferHistoryDao
        .watchAll(HistoryFilter(from: DateTime(2026, 6)))
        .first;
    expect(rows.map((r) => r.record.id), ['jun']);
  });

  test('watchAll text query matches peer label or file name', () async {
    await db.transferHistoryDao.insertRecord(
      record('a', peerLabel: 'Alice'),
      [file('a', 'report.pdf')],
    );
    await db.transferHistoryDao.insertRecord(
      record('b', peerLabel: 'Bob'),
      [file('b', 'photo.jpg')],
    );
    final byName = await db.transferHistoryDao
        .watchAll(const HistoryFilter(query: 'report'))
        .first;
    expect(byName.map((r) => r.record.id), ['a']);
    final byPeer = await db.transferHistoryDao
        .watchAll(const HistoryFilter(query: 'bob'))
        .first;
    expect(byPeer.map((r) => r.record.id), ['b']);
  });

  test('watchRecent caps the result', () async {
    for (var i = 0; i < 5; i++) {
      await db.transferHistoryDao.insertRecord(
        record('r$i', at: DateTime(2026, 6, 25, i)),
        const [],
      );
    }
    final rows = await db.transferHistoryDao.watchRecent(3).first;
    expect(rows, hasLength(3));
    expect(rows.first.record.id, 'r4');
  });

  test('deleteById cascades to file rows', () async {
    await db.transferHistoryDao.insertRecord(record('a'), [file('a', 'x.pdf')]);
    await db.transferHistoryDao.deleteById('a');
    expect(
      await db.transferHistoryDao.watchAll(HistoryFilter.none).first,
      isEmpty,
    );
    final remainingFiles = await db.select(db.transferRecordFiles).get();
    expect(remainingFiles, isEmpty, reason: 'FK cascade removes child rows');
  });

  test('clearAll empties both tables', () async {
    await db.transferHistoryDao.insertRecord(record('a'), [file('a', 'x.pdf')]);
    await db.transferHistoryDao.insertRecord(record('b'), [file('b', 'y.pdf')]);
    await db.transferHistoryDao.clearAll();
    expect(
      await db.transferHistoryDao.watchAll(HistoryFilter.none).first,
      isEmpty,
    );
    expect(await db.select(db.transferRecordFiles).get(), isEmpty);
  });

  test('getById returns the record or null', () async {
    await db.transferHistoryDao.insertRecord(record('a'), const []);
    expect((await db.transferHistoryDao.getById('a'))?.record.id, 'a');
    expect(await db.transferHistoryDao.getById('missing'), isNull);
  });
}
