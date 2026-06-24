import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';

part 'transfer_state.freezed.dart';

/// The single source-of-truth transfer state machine value (Constitution VIII).
///
/// `idle → connecting → handshaking → transferring → done | failed | cancelled`
enum TransferPhase {
  /// Nothing started.
  idle,

  /// Establishing the peer connection.
  connecting,

  /// Connected; exchanging manifest + accept/reject.
  handshaking,

  /// Streaming file chunks.
  transferring,

  /// All files transferred and verified (terminal).
  done,

  /// A typed failure occurred (terminal).
  failed,

  /// Cancelled by either side (terminal).
  cancelled,
}

/// Which end of a transfer this engine instance is.
enum TransferRole {
  /// Sends files (the offerer).
  sender,

  /// Receives files (the answerer).
  receiver,
}

/// Whether [phase] is terminal (no further snapshots will be emitted).
bool isTerminalPhase(TransferPhase phase) =>
    phase == TransferPhase.done ||
    phase == TransferPhase.failed ||
    phase == TransferPhase.cancelled;

/// Byte-progress snapshot; consumers derive %, speed, and ETA from it.
@freezed
abstract class TransferProgress with _$TransferProgress {
  const factory TransferProgress({
    @Default(0) int overallBytesTransferred,
    @Default(0) int overallTotalBytes,
    int? currentFileIndex,
    @Default(0) int currentFileBytesTransferred,
    @Default(0) int currentFileTotalBytes,
  }) = _TransferProgress;
}

/// Immutable snapshot emitted on the engine's broadcast stream.
@freezed
abstract class TransferSnapshot with _$TransferSnapshot {
  const factory TransferSnapshot({
    required TransferPhase phase,
    required TransferRole role,
    required TransferProgress progress,
    @Default(<FileTransferItem>[]) List<FileTransferItem> items,
    AppFailure? failure,
  }) = _TransferSnapshot;

  const TransferSnapshot._();

  /// Whether this snapshot is a terminal state.
  bool get isTerminal => isTerminalPhase(phase);
}
