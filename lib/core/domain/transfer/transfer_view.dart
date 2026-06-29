import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';

part 'transfer_view.freezed.dart';

/// The presentation projection of a [TransferSnapshot] that the Progress and
/// Complete screens bind to — shared by Send (#004) and Receive (#005). Computed,
/// never authoritative: the engine stream is the single source of truth
/// (Constitution VIII). Speed/ETA are derived across snapshots by
/// `TransferProgressProjector` and passed in; the receive-only decision fields
/// are populated while the engine awaits accept/reject.
@freezed
abstract class TransferView with _$TransferView {
  const factory TransferView({
    required TransferPhase phase,
    required TransferRole role,
    @Default(0) double overallProgress,
    @Default(0) int bytesDone,
    @Default(0) int bytesTotal,
    @Default(0) double speedBytesPerSec,
    int? etaSeconds,
    int? currentIndex,
    String? currentFileName,
    @Default(0) int fileCount,
    @Default(<FileTransferItem>[]) List<FileTransferItem> items,
    @Default(Duration.zero) Duration elapsed,
    @Default(false) bool awaitingDecision,
    IncomingOffer? incomingOffer,
    AppFailure? failure,
    @Default(false) bool relayInUse,
  }) = _TransferView;

  const TransferView._();

  /// Project a [snapshot] into a view. [speedBytesPerSec]/[etaSeconds]/[elapsed]
  /// are supplied by the cubit (cross-snapshot timing); [awaitingDecision]/
  /// [incomingOffer] are set by the receive cubit during the accept/reject gate.
  factory TransferView.fromSnapshot(
    TransferSnapshot snapshot, {
    double speedBytesPerSec = 0,
    int? etaSeconds,
    Duration elapsed = Duration.zero,
    bool awaitingDecision = false,
    IncomingOffer? incomingOffer,
  }) {
    final total = snapshot.progress.overallTotalBytes;
    final done = snapshot.progress.overallBytesTransferred;
    final idx = snapshot.progress.currentFileIndex;
    final hasCurrent = idx != null && idx >= 0 && idx < snapshot.items.length;
    return TransferView(
      phase: snapshot.phase,
      role: snapshot.role,
      overallProgress: total == 0 ? 0 : (done / total).clamp(0.0, 1.0),
      bytesDone: done,
      bytesTotal: total,
      speedBytesPerSec: speedBytesPerSec,
      etaSeconds: etaSeconds,
      currentIndex: idx,
      currentFileName: hasCurrent ? snapshot.items[idx].name : null,
      fileCount: snapshot.items.length,
      items: snapshot.items,
      elapsed: elapsed,
      awaitingDecision: awaitingDecision,
      incomingOffer: incomingOffer,
      failure: snapshot.failure,
      relayInUse: snapshot.relayInUse,
    );
  }

  /// Whether the transfer fully completed (all files arrived + verified).
  bool get isDone => phase == TransferPhase.done;

  /// Whether bytes are actively flowing.
  bool get isTransferring => phase == TransferPhase.transferring;

  /// Whether the engine is still establishing/handshaking (pre-bytes).
  bool get isPreparing =>
      phase == TransferPhase.connecting || phase == TransferPhase.handshaking;

  /// Files that fully arrived and passed integrity (receiver) / fully sent.
  List<FileTransferItem> get completedItems =>
      items.where((i) => i.status == FileItemStatus.completed).toList();

  /// Count of completed files.
  int get completedCount => completedItems.length;

  /// A terminal outcome where some — but not all — files completed (FR-013a):
  /// the verified files are kept, the in-flight one discarded.
  bool get isPartial =>
      isTerminalPhase(phase) &&
      phase != TransferPhase.done &&
      completedCount > 0;
}
