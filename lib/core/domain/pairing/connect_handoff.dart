import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// The routing contract for the shared `/connect` pairing hub (#004), owned by
/// core so the Send and Receive features exchange it via navigation without
/// importing each other (Constitution XI).
///
/// Passed as `go_router` `extra` into the Connect route.
class ConnectRequest {
  const ConnectRequest({required this.role});

  /// Which side this device is — sender (Send) or receiver (Receive #005).
  final TransferRole role;
}

/// Returned (via `context.pop`) from the Connect route once the direct channel
/// is open. Ownership of [transport] transfers to the caller.
class ConnectResult {
  const ConnectResult({required this.transport});

  /// The open data channel, handed off from the pairing layer.
  final DataTransport transport;
}
