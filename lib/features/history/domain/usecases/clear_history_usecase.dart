import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/result.dart';

/// Clears all history records (#006, US5). Record-only — files on disk are
/// never deleted (FR-025).
@injectable
class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._repository);

  final TransferHistoryRepository _repository;

  Future<Result<void>> call() => _repository.clearAll();
}
