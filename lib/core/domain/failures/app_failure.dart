import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Enumerates known, recoverable failure modes across the app.
///
/// The peer-to-peer transport set (#002) lives alongside the #001 foundation
/// variants. These are typed only — user-facing localization happens at the UI
/// layer (#004/#005), never here (Constitution XIV).
@freezed
sealed class AppFailure with _$AppFailure {
  /// An unexpected/unclassified error.
  const factory AppFailure.unexpected({String? message, Object? error}) =
      AppFailureUnexpected;

  /// A feature that is intentionally not implemented yet (placeholder flows).
  const factory AppFailure.notImplemented() = AppFailureNotImplemented;

  // --- #003 signaling / pairing failures ---

  /// The signaling relay could not be reached (server down / no network).
  const factory AppFailure.signalingUnreachable() =
      AppFailureSignalingUnreachable;

  /// The signaling exchange / handshake did not complete in time.
  const factory AppFailure.signalingTimeout() = AppFailureSignalingTimeout;

  /// The pairing code's TTL elapsed, or its room was torn down.
  const factory AppFailure.roomExpired() = AppFailureRoomExpired;

  /// The code is valid but its room already holds two peers.
  const factory AppFailure.roomFull() = AppFailureRoomFull;

  /// The entered code is unknown or malformed.
  const factory AppFailure.invalidCode() = AppFailureInvalidCode;

  /// Too many invalid join attempts on this connection.
  const factory AppFailure.rateLimited() = AppFailureRateLimited;

  // --- #002 transport / transfer / file failures ---

  /// The peer could not be reached / no connection established in time.
  const factory AppFailure.peerUnreachable() = AppFailurePeerUnreachable;

  /// ICE connectivity negotiation failed.
  const factory AppFailure.iceFailed() = AppFailureIceFailed;

  /// Neither a direct path nor the TURN relay could carry the connection
  /// (#014) — relay unreachable/misconfigured while direct also failed. Distinct
  /// from `peerUnreachable` so the UI can hint that connectivity (not the peer)
  /// is the problem. Direct-only transfers are unaffected when this occurs.
  const factory AppFailure.relayUnavailable() = AppFailureRelayUnavailable;

  /// An established connection dropped mid-session (disconnect / stall).
  const factory AppFailure.connectionLost() = AppFailureConnectionLost;

  /// The data channel closed unexpectedly.
  const factory AppFailure.dataChannelClosed() = AppFailureDataChannelClosed;

  /// The transfer was cancelled by either side.
  const factory AppFailure.transferCancelled() = AppFailureTransferCancelled;

  /// The receiver rejected the incoming session manifest.
  const factory AppFailure.transferRejected() = AppFailureTransferRejected;

  /// A received file's hash did not match the sender's declared hash.
  const factory AppFailure.integrityCheckFailed({required int fileIndex}) =
      AppFailureIntegrityCheckFailed;

  /// A source file could not be read on the sender.
  const factory AppFailure.fileReadFailed() = AppFailureFileReadFailed;

  /// A destination/quarantine file could not be written on the receiver.
  const factory AppFailure.fileWriteFailed() = AppFailureFileWriteFailed;

  /// A write failed because the device is out of storage space.
  const factory AppFailure.storageFull() = AppFailureStorageFull;

  /// A generic transport/network error.
  const factory AppFailure.networkError() = AppFailureNetworkError;

  // --- #010 settings failures ---

  /// A required OS permission (photo library / notifications) was denied.
  const factory AppFailure.permissionDenied() = AppFailurePermissionDenied;

  /// A custom signaling-endpoint override failed scheme/flavor validation
  /// (`wss` any flavor, `ws` dev-only) or was unparseable (FR-014).
  const factory AppFailure.invalidSignalingEndpoint() =
      AppFailureInvalidSignalingEndpoint;
}
