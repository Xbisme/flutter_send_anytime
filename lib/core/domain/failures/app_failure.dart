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

  // --- #002 transport / transfer / file failures ---

  /// The peer could not be reached / no connection established in time.
  const factory AppFailure.peerUnreachable() = AppFailurePeerUnreachable;

  /// ICE connectivity negotiation failed.
  const factory AppFailure.iceFailed() = AppFailureIceFailed;

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
}
