import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';

/// The single core boundary for transfer history (#006), shared by Send,
/// Receive, History, and Home (Constitution XI — it lives in `core/` because no
/// feature may import another). Persists transfer **metadata only**; it never
/// reads, writes, moves, or deletes a file on disk (Constitution I/II; FR-025).
abstract interface class TransferHistoryRepository {
  /// Persist one finished transfer. Callers generate a fresh id and call once
  /// per agreed-and-started terminal transfer (FR-001/FR-004).
  Future<Result<void>> record(TransferRecord record);

  /// Reactive, newest-first list for the History tab, narrowed by [filter].
  Stream<List<TransferRecord>> watch(HistoryFilter filter);

  /// Reactive newest-first list capped at [limit] for the Home recent area.
  Stream<List<TransferRecord>> watchRecent(int limit);

  /// A single record by [id] (detail fallback).
  Future<Result<TransferRecord?>> getById(String id);

  /// Remove one record (record-only — never touches files, FR-025).
  Future<Result<void>> deleteById(String id);

  /// Remove all records (record-only — never touches files, FR-025).
  Future<Result<void>> clearAll();
}
