import 'package:drift/drift.dart';
import 'package:safe_send/core/data/database/app_database.dart';
import 'package:safe_send/core/data/database/tables/transfer_record_files_table.dart';
import 'package:safe_send/core/data/database/tables/transfer_records_table.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';

part 'transfer_history_dao.g.dart';

/// A record row joined with its file rows (DAO ↔ repository hand-off type). The
/// repository maps this to the `TransferRecord` domain entity.
class RecordWithFiles {
  const RecordWithFiles(this.record, this.files);

  final TransferRecordRow record;
  final List<TransferRecordFileRow> files;
}

/// Data access for transfer history (#006). Reads are reactive drift streams;
/// writes are transactional (parent + children atomically). The direction and
/// date-range parts of a filter are applied in SQL; the text query is applied
/// in Dart over the loaded record + file names (correct + simple at this scale,
/// per research Decision 5).
@DriftAccessor(tables: [TransferRecords, TransferRecordFiles])
class TransferHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$TransferHistoryDaoMixin {
  TransferHistoryDao(super.attachedDatabase);

  /// Insert one record and its files atomically.
  Future<void> insertRecord(
    TransferRecordsCompanion record,
    List<TransferRecordFilesCompanion> files,
  ) {
    return transaction(() async {
      await into(transferRecords).insert(record);
      for (final f in files) {
        await into(transferRecordFiles).insert(f);
      }
    });
  }

  /// Reactive, newest-first list narrowed by [filter].
  Stream<List<RecordWithFiles>> watchAll(HistoryFilter filter) {
    final query = select(transferRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (filter.direction != null) {
      query.where((t) => t.direction.equals(filter.direction!.name));
    }
    if (filter.from != null) {
      query.where((t) => t.createdAt.isBiggerOrEqualValue(filter.from!));
    }
    if (filter.to != null) {
      query.where((t) => t.createdAt.isSmallerOrEqualValue(filter.to!));
    }
    return query.watch().asyncMap((rows) => _attachFiles(rows, filter));
  }

  /// Reactive newest-first list capped at [limit] (Home recent).
  Stream<List<RecordWithFiles>> watchRecent(int limit) {
    final query = select(transferRecords)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    return query.watch().asyncMap((rows) => _attachFiles(rows, null));
  }

  /// A single record with its files, or null.
  Future<RecordWithFiles?> getById(String id) async {
    final row = await (select(
      transferRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final files = await _filesFor([id]);
    return RecordWithFiles(row, files[id] ?? const []);
  }

  /// Delete one record; its file rows cascade away.
  Future<void> deleteById(String id) =>
      (delete(transferRecords)..where((t) => t.id.equals(id))).go();

  /// Remove all records and files.
  Future<void> clearAll() => transaction(() async {
    await delete(transferRecordFiles).go();
    await delete(transferRecords).go();
  });

  Future<List<RecordWithFiles>> _attachFiles(
    List<TransferRecordRow> rows,
    HistoryFilter? filter,
  ) async {
    if (rows.isEmpty) return const [];
    final byRecord = await _filesFor(rows.map((r) => r.id).toList());
    var result = [
      for (final r in rows) RecordWithFiles(r, byRecord[r.id] ?? const []),
    ];
    final q = filter?.normalizedQuery?.toLowerCase();
    if (q != null) {
      result = result
          .where(
            (rf) =>
                rf.record.peerLabel.toLowerCase().contains(q) ||
                rf.files.any((f) => f.name.toLowerCase().contains(q)),
          )
          .toList();
    }
    return result;
  }

  Future<Map<String, List<TransferRecordFileRow>>> _filesFor(
    List<String> ids,
  ) async {
    final fileRows =
        await (select(transferRecordFiles)
              ..where((f) => f.recordId.isIn(ids))
              ..orderBy([(f) => OrderingTerm.asc(f.position)]))
            .get();
    final byRecord = <String, List<TransferRecordFileRow>>{};
    for (final f in fileRows) {
      byRecord.putIfAbsent(f.recordId, () => []).add(f);
    }
    return byRecord;
  }
}
