import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

/// Lifecycle phase of a background surface, projected from [TransferPhase].
///
/// Only the states a background surface cares about: it is live while
/// [transferring], then settles to one terminal look before dismissal.
enum BackgroundPhase { transferring, done, failed, cancelled }

/// Maps the engine's [TransferPhase] onto the coarser [BackgroundPhase] the OS
/// surfaces render. Non-terminal, non-transferring phases (idle/connecting/
/// handshaking) collapse to [BackgroundPhase.transferring] because a surface
/// only ever exists once a transfer is under way.
BackgroundPhase mapBackgroundPhase(TransferPhase phase) => switch (phase) {
  TransferPhase.done => BackgroundPhase.done,
  TransferPhase.failed => BackgroundPhase.failed,
  TransferPhase.cancelled => BackgroundPhase.cancelled,
  _ => BackgroundPhase.transferring,
};

/// Display-ready view model for an OS background surface (iOS Live Activity /
/// Android foreground-service notification).
///
/// A pure projection of one transfer snapshot/view + static session metadata.
/// All text is already localized and all numbers already formatted (the native
/// iOS widget renders the strings it is given — Constitution XIV). `percent` is
/// kept numeric because the Live Activity ring/bar geometry needs it.
class BackgroundTransferState {
  const BackgroundTransferState({
    required this.direction,
    required this.peerName,
    required this.fileCount,
    required this.phase,
    required this.percent,
    required this.title,
    required this.peerLine,
    required this.speedLabel,
    required this.bytesLabel,
    required this.etaLabel,
    required this.cancelLabel,
  });

  /// Send vs receive — chooses accent, icon, and verb on the surface.
  final TransferDirection direction;

  /// Peer/device label (#010 custom name or a generic fallback).
  final String peerName;

  /// Number of files in the session.
  final int fileCount;

  /// Coarse surface phase.
  final BackgroundPhase phase;

  /// Overall progress, 0–100.
  final int percent;

  /// e.g. "Đang gửi · 18 tệp".
  final String title;

  /// e.g. "tới Minh's iPhone" / "từ MacBook của Linh".
  final String peerLine;

  /// Mono, e.g. "2.4 MB/s".
  final String speedLabel;

  /// Mono, e.g. "153 / 240 MB".
  final String bytesLabel;

  /// Mono, e.g. "còn 0:48" (empty when ETA is unknown).
  final String etaLabel;

  /// Localized label for the Android notification's single Cancel action.
  final String cancelLabel;

  bool get isTerminal => phase != BackgroundPhase.transferring;

  /// String map pushed to the iOS Live Activity `ContentState` (App Group) and
  /// used to build the Android notification. Keys MUST match the native widget
  /// (see contracts/live_activity_state.md).
  Map<String, dynamic> toContentState() => <String, dynamic>{
    'direction': direction == TransferDirection.sent ? 'send' : 'receive',
    'title': title,
    'peerLine': peerLine,
    'percent': percent,
    'speedLabel': speedLabel,
    'bytesLabel': bytesLabel,
    'etaLabel': etaLabel,
    'phase': phase.name,
  };
}
