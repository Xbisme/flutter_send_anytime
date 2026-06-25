import 'package:drift/drift.dart';
import 'package:safe_send/core/data/database/tables/transfer_records_table.dart';

/// Child table: one row per file within a [TransferRecords] row (#006). The
/// `record_id` FK cascades on delete so removing a record (or clearing all)
/// drops its file rows — but **never touches the files on disk** (FR-025).
@DataClassName('TransferRecordFileRow')
class TransferRecordFiles extends Table {
  /// Auto-increment surrogate key.
  IntColumn get id => integer().autoIncrement()();

  /// Owning record id.
  TextColumn get recordId =>
      text().references(TransferRecords, #id, onDelete: KeyAction.cascade)();

  /// File basename (no directory component).
  TextColumn get name => text()();

  /// Best-effort content type, or null.
  TextColumn get mimeType => text().nullable()();

  /// File size in bytes.
  IntColumn get size => integer()();

  /// Source path (sent — for re-send existence) / final path (received — for
  /// open); null when unknown. Read-only; never used to write.
  TextColumn get path => text().nullable()();

  /// Whether this file completed and was kept in the transfer (FR-013a).
  BoolColumn get included => boolean().withDefault(const Constant(true))();

  /// Manifest position, to preserve order in the detail list.
  IntColumn get position => integer()();
}
