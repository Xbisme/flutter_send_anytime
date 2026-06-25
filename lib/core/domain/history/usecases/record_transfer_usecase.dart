import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';

/// The write half of the core history capability (#006). Injected into the Send
/// and Receive cubits, which call it once when an agreed-and-started transfer
/// reaches a terminal state (FR-001/FR-004). Recording is best-effort: a
/// failure is logged by the caller and never alters the user-visible transfer
/// outcome (see [contracts/transfer-history-repository.md]).
@injectable
class RecordTransferUseCase {
  const RecordTransferUseCase(this._repository);

  final TransferHistoryRepository _repository;

  Future<Result<void>> call(TransferRecord record) =>
      _repository.record(record);
}
