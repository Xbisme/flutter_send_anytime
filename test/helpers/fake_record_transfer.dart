import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/result.dart';

/// A no-op [RecordTransferUseCase] for tests that don't assert on history
/// recording (#006). Recording is best-effort and never affects the transfer
/// outcome, so swallowing it keeps unrelated send/receive tests focused.
class FakeRecordTransfer implements RecordTransferUseCase {
  @override
  Future<Result<void>> call(TransferRecord record) async =>
      const Result.success(null);
}
