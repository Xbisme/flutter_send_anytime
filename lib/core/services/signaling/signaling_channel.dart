import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/result.dart';

part 'signaling_channel.freezed.dart';

/// A connection-setup metadata message. Carries SDP / ICE / control only —
/// **never file bytes** (Constitution I/VIII, FR-002/031). There is
/// structurally no byte-carrying variant.
@freezed
sealed class SignalingMessage with _$SignalingMessage {
  /// SDP offer (sender → receiver).
  const factory SignalingMessage.offer({required String sdp}) = SignalingOffer;

  /// SDP answer (receiver → sender).
  const factory SignalingMessage.answer({required String sdp}) =
      SignalingAnswer;

  /// A trickled ICE candidate.
  const factory SignalingMessage.iceCandidate({
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) = SignalingIceCandidate;

  /// Optional graceful close signal.
  const factory SignalingMessage.bye() = SignalingBye;
}

/// The transport-agnostic seam for exchanging connection-setup metadata with
/// the remote peer. The engine depends ONLY on this interface (FR-006); the
/// real WebSocket implementation arrives in #003.
abstract interface class SignalingChannel {
  /// Messages arriving from the remote peer (broadcast).
  Stream<SignalingMessage> get incoming;

  /// Send a message to the remote peer. Transport errors surface as an
  /// `AppFailure` inside the `Result` — never thrown.
  Future<Result<void>> send(SignalingMessage message);

  /// Release the channel (idempotent). Messages after close are ignored.
  Future<void> close();
}
