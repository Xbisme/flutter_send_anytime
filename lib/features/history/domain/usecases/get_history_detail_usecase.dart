import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';

/// Loads a single history record by id (#006, US3). The detail page receives
/// the record directly via navigation `extra`; this is the fallback path.
@injectable
class GetHistoryDetailUseCase {
  const GetHistoryDetailUseCase(this._repository);

  final TransferHistoryRepository _repository;

  Future<Result<TransferRecord?>> call(String id) => _repository.getById(id);
}
