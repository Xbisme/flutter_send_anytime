import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/result.dart';

/// Deletes one history record (#006, US5). Record-only — the underlying files
/// on disk are never touched (FR-025).
@injectable
class DeleteRecordUseCase {
  const DeleteRecordUseCase(this._repository);

  final TransferHistoryRepository _repository;

  Future<Result<void>> call(String id) => _repository.deleteById(id);
}
