import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';

/// Maps a terminal transfer [TransferView] to the recorded outcome (#006,
/// research Decision 3). Precedence: a fully-done transfer is `completed`; a
/// terminal-but-not-done transfer that kept some files is `partial` (FR-013a);
/// an explicit cancel with nothing kept is `cancelled`; anything else `failed`.
TransferRecordStatus historyStatusForView(TransferView view) {
  if (view.phase == TransferPhase.done) return TransferRecordStatus.completed;
  if (view.isPartial) return TransferRecordStatus.partial;
  if (view.phase == TransferPhase.cancelled) {
    return TransferRecordStatus.cancelled;
  }
  return TransferRecordStatus.failed;
}
