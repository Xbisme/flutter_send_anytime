import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';

/// Streams the history list narrowed by a [HistoryFilter] (#006, US1/US4).
@injectable
class WatchHistoryUseCase {
  const WatchHistoryUseCase(this._repository);

  final TransferHistoryRepository _repository;

  Stream<List<TransferRecord>> call(HistoryFilter filter) =>
      _repository.watch(filter);
}
