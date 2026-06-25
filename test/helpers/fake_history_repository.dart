import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';

/// An in-memory [TransferHistoryRepository] for widget tests that render
/// surfaces touching history (Home, navigation) without opening the real drift
/// database (which needs platform channels unavailable in `flutter test`).
class FakeHistoryRepository implements TransferHistoryRepository {
  List<TransferRecord> records = const [];

  @override
  Stream<List<TransferRecord>> watch(HistoryFilter filter) =>
      Stream.value(records);

  @override
  Stream<List<TransferRecord>> watchRecent(int limit) =>
      Stream.value(records.take(limit).toList());

  @override
  Future<Result<void>> record(TransferRecord record) async =>
      const Result.success(null);

  @override
  Future<Result<TransferRecord?>> getById(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteById(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void>> clearAll() async => const Result.success(null);
}
