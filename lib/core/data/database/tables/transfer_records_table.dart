import 'package:drift/drift.dart';

/// Parent table: one row per finished transfer (#006). Enum columns store the
/// enum **name** (self-describing, tolerant of reordering). [createdAt] is
/// indexed for newest-first ordering and date-range filtering.
@DataClassName('TransferRecordRow')
class TransferRecords extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// `TransferDirection` name (`sent` / `received`).
  TextColumn get direction => text()();

  /// `TransferRecordStatus` name.
  TextColumn get status => text()();

  /// `PairingMethod` name.
  TextColumn get pairingMethod => text()();

  /// Generic peer label; empty until real device names arrive (#010).
  TextColumn get peerLabel => text().withDefault(const Constant(''))();

  /// Number of files offered in the transfer.
  IntColumn get fileCount => integer()();

  /// Sum of offered file sizes (bytes).
  IntColumn get totalBytes => integer()();

  /// Terminal-state timestamp (UTC).
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
