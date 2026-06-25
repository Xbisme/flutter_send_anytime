// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_history_dao.dart';

// ignore_for_file: type=lint
mixin _$TransferHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $TransferRecordsTable get transferRecords => attachedDatabase.transferRecords;
  $TransferRecordFilesTable get transferRecordFiles =>
      attachedDatabase.transferRecordFiles;
  TransferHistoryDaoManager get managers => TransferHistoryDaoManager(this);
}

class TransferHistoryDaoManager {
  final _$TransferHistoryDaoMixin _db;
  TransferHistoryDaoManager(this._db);
  $$TransferRecordsTableTableManager get transferRecords =>
      $$TransferRecordsTableTableManager(
        _db.attachedDatabase,
        _db.transferRecords,
      );
  $$TransferRecordFilesTableTableManager get transferRecordFiles =>
      $$TransferRecordFilesTableTableManager(
        _db.attachedDatabase,
        _db.transferRecordFiles,
      );
}
