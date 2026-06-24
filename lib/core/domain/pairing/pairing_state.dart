import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';

part 'pairing_state.freezed.dart';

/// The signaling-client pairing lifecycle (#003), exposed as a stream and
/// consumed by `PairingCubit`. Drives the flow from connecting through a peer
/// being present to the WebRTC data channel opening, or a typed failure.
///
/// `idle → connecting → hosting | joining → peerPresent → connected`
/// with `failed(AppFailure)` reachable from any active state, and `closed`
/// after teardown.
@freezed
sealed class PairingState with _$PairingState {
  /// Nothing started.
  const factory PairingState.idle() = PairingIdle;

  /// Opening the WebSocket to the relay.
  const factory PairingState.connecting() = PairingConnecting;

  /// Sender: code issued; waiting for the receiver to join.
  const factory PairingState.hosting(PairingCode code) = PairingHosting;

  /// Receiver: code submitted; awaiting room join confirmation.
  const factory PairingState.joining() = PairingJoining;

  /// Both peers are in the room; the WebRTC handshake is running.
  const factory PairingState.peerPresent() = PairingPeerPresent;

  /// The direct data channel is open — ready for transfer (#004/#005).
  const factory PairingState.connected() = PairingConnected;

  /// A typed failure (unreachable/timeout/expired/full/invalid/rate-limited/
  /// connection-lost). Terminal.
  const factory PairingState.failed(AppFailure failure) = PairingFailed;

  /// The client was disposed/closed. Terminal.
  const factory PairingState.closed() = PairingClosed;
}
