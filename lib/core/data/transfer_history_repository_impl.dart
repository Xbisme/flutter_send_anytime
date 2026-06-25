import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/data/daos/transfer_history_dao.dart';
import 'package:safe_send/core/data/database/app_database.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// drift-backed [TransferHistoryRepository]. Maps domain ↔ drift rows, parses
/// enum names with safe-default fallback, and wraps every call in [Result]
/// (Constitution V — the DAO throws, the repository catches). Persists metadata
/// only; never reads, writes, or deletes a file on disk (FR-025).
@LazySingleton(as: TransferHistoryRepository)
class TransferHistoryRepositoryImpl implements TransferHistoryRepository {
  TransferHistoryRepositoryImpl(AppDatabase db) : _dao = db.transferHistoryDao;

  final TransferHistoryDao _dao;

  @override
  Future<Result<void>> record(TransferRecord record) async {
    try {
      await _dao.insertRecord(
        TransferRecordsCompanion.insert(
          id: record.id,
          direction: record.direction.name,
          status: record.status.name,
          pairingMethod: record.pairingMethod.name,
          peerLabel: Value(record.peerLabel),
          fileCount: record.fileCount,
          totalBytes: record.totalBytes,
          createdAt: record.createdAt,
        ),
        [
          for (var i = 0; i < record.files.length; i++)
            TransferRecordFilesCompanion.insert(
              recordId: record.id,
              name: record.files[i].name,
              size: record.files[i].size,
              mimeType: Value(record.files[i].mimeType),
              path: Value(record.files[i].path),
              included: Value(record.files[i].included),
              position: i,
            ),
        ],
      );
      return const Result.success(null);
    } on Object catch (e) {
      AppLogger.error('history.record failed', e);
      return const Result.failure(AppFailure.fileWriteFailed());
    }
  }

  @override
  Stream<List<TransferRecord>> watch(HistoryFilter filter) =>
      _dao.watchAll(filter).map((rows) => rows.map(_toDomain).toList());

  @override
  Stream<List<TransferRecord>> watchRecent(int limit) =>
      _dao.watchRecent(limit).map((rows) => rows.map(_toDomain).toList());

  @override
  Future<Result<TransferRecord?>> getById(String id) async {
    try {
      final row = await _dao.getById(id);
      return Result.success(row == null ? null : _toDomain(row));
    } on Object catch (e) {
      AppLogger.error('history.getById failed', e);
      return const Result.failure(AppFailure.fileReadFailed());
    }
  }

  @override
  Future<Result<void>> deleteById(String id) async {
    try {
      await _dao.deleteById(id);
      return const Result.success(null);
    } on Object catch (e) {
      AppLogger.error('history.deleteById failed', e);
      return const Result.failure(AppFailure.unexpected());
    }
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await _dao.clearAll();
      return const Result.success(null);
    } on Object catch (e) {
      AppLogger.error('history.clearAll failed', e);
      return const Result.failure(AppFailure.unexpected());
    }
  }

  TransferRecord _toDomain(RecordWithFiles rf) {
    final r = rf.record;
    return TransferRecord(
      id: r.id,
      direction: _direction(r.direction),
      status: _status(r.status),
      pairingMethod: _pairingMethod(r.pairingMethod),
      peerLabel: r.peerLabel,
      fileCount: r.fileCount,
      totalBytes: r.totalBytes,
      createdAt: r.createdAt,
      files: [
        for (final f in rf.files)
          RecordedFile(
            name: f.name,
            size: f.size,
            mimeType: f.mimeType,
            path: f.path,
            included: f.included,
          ),
      ],
    );
  }

  TransferDirection _direction(String name) => TransferDirection.values
      .firstWhere((d) => d.name == name, orElse: () => TransferDirection.sent);

  TransferRecordStatus _status(String name) =>
      TransferRecordStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => TransferRecordStatus.failed,
      );

  PairingMethod _pairingMethod(String name) => PairingMethod.values.firstWhere(
    (p) => p.name == name,
    orElse: () => PairingMethod.sixDigitCode,
  );
}
