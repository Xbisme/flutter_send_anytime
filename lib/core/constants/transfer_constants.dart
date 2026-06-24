/// Centralized transport/transfer tuning + protocol constants (#002).
///
/// Single source of truth — channel labels, opcodes, sizes, thresholds, and
/// timeouts MUST NOT be duplicated as literals elsewhere (Constitution VIII).
abstract final class TransferConstants {
  /// Wire protocol version (manifest `v` field; gated on receive).
  static const int kProtocolVersion = 1;

  /// Data-channel label used for the transfer channel.
  static const String kDataChannelLabel = 'safesend-transfer';

  /// Per-`chunk` payload size in bytes (16 KiB) — broadly safe across SCTP
  /// implementations; bounds the streamed read buffer (research R-01).
  static const int kChunkSize = 16 * 1024;

  /// `bufferedAmountLowThreshold` for the data channel (256 KiB).
  static const int kLowWaterMark = 256 * 1024;

  /// Pause sending when the channel's outbound buffer exceeds this (1 MiB);
  /// resume on the buffered-amount-low signal (research R-03).
  static const int kHighWaterMark = 1024 * 1024;

  /// Timeout for establishing the peer connection.
  static const Duration kConnectTimeout = Duration(seconds: 30);

  /// Timeout for the manifest + accept/reject handshake.
  static const Duration kHandshakeTimeout = Duration(seconds: 15);

  /// Zero-progress watchdog during an active transfer.
  static const Duration kStallTimeout = Duration(seconds: 30);

  /// Hidden quarantine subdirectory (created under the destination volume).
  static const String kQuarantineDirName = '.safesend_tmp';
}

/// Framed-protocol opcodes. Every data-channel message is `[opcode][payload]`.
///
/// Control opcodes carry UTF-8 JSON; [chunk] carries raw file bytes.
abstract final class TransferOpcode {
  /// Session manifest (sender → receiver).
  static const int manifest = 0x01;

  /// Manifest accepted (receiver → sender).
  static const int accept = 0x02;

  /// Manifest rejected (receiver → sender).
  static const int reject = 0x03;

  /// Start of a file's bytes (sender → receiver).
  static const int fileStart = 0x04;

  /// Raw file bytes (sender → receiver); payload is not JSON.
  static const int chunk = 0x05;

  /// End of a file's bytes, carries the per-file SHA-256 (sender → receiver).
  static const int fileComplete = 0x06;

  /// All files done (sender → receiver).
  static const int sessionComplete = 0x07;

  /// Cancel/abort (either → either).
  static const int cancel = 0x08;
}
