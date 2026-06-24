import 'package:safesend_signaling/safesend_signaling.dart';

/// App-side signaling/pairing tunables. The wire-protocol constants themselves
/// live in the shared `safesend_signaling` package (single source of truth,
/// Constitution VIII) and are re-exported here for convenient access.
export 'package:safesend_signaling/safesend_signaling.dart'
    show RelayKind, SignalingProtocol;

/// Client-side timeouts for the signaling/pairing phase.
abstract final class SignalingTimeouts {
  /// Max time to open the WebSocket + receive `code-issued` / join ack.
  static const connect = Duration(seconds: 10);

  /// Max time to wait for the peer to join + complete the SDP/ICE handshake
  /// (until the data channel opens) once both peers are in the room.
  static const handshake = Duration(seconds: 30);

  /// Convenience: the issued-code TTL mirrored from the shared protocol.
  static const Duration codeTtl = SignalingProtocol.defaultTtl;
}
