import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';

part 'send_transfer_view.freezed.dart';

/// The presentation projection of a [TransferSnapshot] the Progress/Complete
/// views bind to (#004). Computed, never authoritative — the engine stream is
/// the single source of truth (Constitution VIII). Speed/ETA are derived by the
/// cubit across consecutive snapshots and passed in.
@freezed
abstract class SendTransferView with _$SendTransferView {
  const factory SendTransferView({
    required TransferPhase phase,
    @Default(0) double overallProgress,
    @Default(0) int bytesSent,
    @Default(0) int bytesTotal,
    @Default(0) double speedBytesPerSec,
    int? etaSeconds,
    int? currentIndex,
    String? currentFileName,
    @Default(0) int fileCount,
    @Default(<FileTransferItem>[]) List<FileTransferItem> items,
    @Default(Duration.zero) Duration elapsed,
    AppFailure? failure,
  }) = _SendTransferView;

  const SendTransferView._();

  /// Project a [snapshot] into a view. [speedBytesPerSec]/[etaSeconds]/[elapsed]
  /// are supplied by the cubit (they need cross-snapshot timing).
  factory SendTransferView.fromSnapshot(
    TransferSnapshot snapshot, {
    double speedBytesPerSec = 0,
    int? etaSeconds,
    Duration elapsed = Duration.zero,
  }) {
    final total = snapshot.progress.overallTotalBytes;
    final sent = snapshot.progress.overallBytesTransferred;
    final idx = snapshot.progress.currentFileIndex;
    final hasCurrent = idx != null && idx >= 0 && idx < snapshot.items.length;
    return SendTransferView(
      phase: snapshot.phase,
      overallProgress: total == 0 ? 0 : (sent / total).clamp(0.0, 1.0),
      bytesSent: sent,
      bytesTotal: total,
      speedBytesPerSec: speedBytesPerSec,
      etaSeconds: etaSeconds,
      currentIndex: idx,
      currentFileName: hasCurrent ? snapshot.items[idx].name : null,
      fileCount: snapshot.items.length,
      items: snapshot.items,
      elapsed: elapsed,
      failure: snapshot.failure,
    );
  }

  /// Whether the send has fully completed.
  bool get isDone => phase == TransferPhase.done;

  /// Whether bytes are actively flowing.
  bool get isTransferring => phase == TransferPhase.transferring;

  /// Whether the engine is still establishing/handshaking (pre-bytes).
  bool get isPreparing =>
      phase == TransferPhase.connecting || phase == TransferPhase.handshaking;
}
