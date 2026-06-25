import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';

/// Streams the most recent transfers for the Home recent area (#006, US6).
@injectable
class WatchRecentTransfersUseCase {
  const WatchRecentTransfersUseCase(this._repository);

  final TransferHistoryRepository _repository;

  /// At most [limit] newest records.
  Stream<List<TransferRecord>> call({int limit = 5}) =>
      _repository.watchRecent(limit);
}
