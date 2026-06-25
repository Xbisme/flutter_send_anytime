import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// The routing contract for the shared `/connect` pairing hub (#004), owned by
/// core so the Send and Receive features exchange it via navigation without
/// importing each other (Constitution XI).
///
/// Passed as `go_router` `extra` into the Connect route.
class ConnectRequest {
  const ConnectRequest({
    required this.role,
    this.openScanner = false,
    this.autoJoinCode,
  });

  /// Which side this device is — sender (Send) or receiver (Receive #005).
  final TransferRole role;

  /// When true (receiver only), the Connect hub opens the QR scanner straight
  /// away — used by the Home "Quét QR" quick action (#007, FR-019).
  final bool openScanner;

  /// A 6-digit code to auto-join immediately (receiver only) — set when the
  /// receiver arrived via a share-link invite (#008, FR-012). The receiver
  /// panel joins this code on init and records `pairingMethod = shareLink`.
  final String? autoJoinCode;
}

/// Returned (via `context.pop`) from the Connect route once the direct channel
/// is open. Ownership of [transport] transfers to the caller.
class ConnectResult {
  const ConnectResult({
    required this.transport,
    this.method = PairingMethod.sixDigitCode,
  });

  /// The open data channel, handed off from the pairing layer.
  final DataTransport transport;

  /// How *this* device paired — `qr` when the QR tab/scanner was used, else
  /// `sixDigitCode` (#007, FR-018). Carried into the history record.
  final PairingMethod method;
}
