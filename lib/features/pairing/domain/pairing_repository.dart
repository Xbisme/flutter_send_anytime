import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// Orchestrates a pairing session: drives the signaling client through the
/// 6-digit rendezvous, then runs the WebRTC handshake to open the direct
/// channel. Exposes a single [state] stream the UI (#004/#005) consumes.
abstract interface class PairingRepository {
  /// Pairing lifecycle, ending in `connected` (channel open) or `failed`.
  Stream<PairingState> get state;

  /// Sender path: generate a code and wait for a peer + connection.
  Future<Result<PairingCode>> host();

  /// Receiver path: join with [code] and connect.
  Future<Result<void>> join(String code);

  /// Transfer ownership of the connected data channel out of the pairing layer
  /// (#004). Returns the open transport and clears the internal reference so
  /// [dispose] will NOT close it. Returns null if not connected. Single-use.
  DataTransport? takeTransport();

  /// Tear down the session and release the socket/connection.
  Future<void> dispose();
}
