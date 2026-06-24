import 'dart:async';

import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

/// The real network implementation of the #002 [SignalingChannel] seam.
///
/// It does NOT own the socket — the `SignalingClient` owns it and feeds inbound
/// relay frames via [deliverFromPeer]. This adapter only maps between the #002
/// [SignalingMessage] vocabulary and the shared [RelayFrame]/[ByeFrame] wire
/// frames. The #002 transfer engine consumes it unchanged.
class WebSocketSignalingChannel implements SignalingChannel {
  WebSocketSignalingChannel({required void Function(SignalingFrame) sendFrame})
    : _sendFrame = sendFrame;

  final void Function(SignalingFrame) _sendFrame;

  // Broadcast so close() completes even if the engine never subscribed (a
  // failure before peerPresent). The connector attaches its listener at
  // peerPresent, before any relay frame is routed, so none are dropped.
  final _inbound = StreamController<SignalingMessage>.broadcast();
  var _closed = false;

  @override
  Stream<SignalingMessage> get incoming => _inbound.stream;

  @override
  Future<Result<void>> send(SignalingMessage message) async {
    if (_closed) return const Result.failure(AppFailure.dataChannelClosed());
    try {
      _sendFrame(_toFrame(message));
      return const Result.success(null);
    } on Object catch (error) {
      AppLogger.error('signaling relay send failed (${error.runtimeType})');
      return const Result.failure(AppFailure.networkError());
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_inbound.isClosed) await _inbound.close();
  }

  /// Push a peer message into [incoming]. Called by the owning client when a
  /// `relay` (or `peer-left`) frame arrives.
  void deliverFromPeer(SignalingMessage message) {
    if (_closed || _inbound.isClosed) return;
    _inbound.add(message);
  }

  /// Map an inbound wire frame to a #002 [SignalingMessage], or null if the
  /// frame is not a peer relay (control frames are handled by the client).
  static SignalingMessage? messageFromFrame(SignalingFrame frame) =>
      switch (frame) {
        RelayFrame(kind: RelayKind.offer, :final sdp) => SignalingMessage.offer(
          sdp: sdp ?? '',
        ),
        RelayFrame(kind: RelayKind.answer, :final sdp) =>
          SignalingMessage.answer(sdp: sdp ?? ''),
        RelayFrame(
          kind: RelayKind.ice,
          :final candidate,
          :final sdpMid,
          :final sdpMLineIndex,
        ) =>
          SignalingMessage.iceCandidate(
            candidate: candidate ?? '',
            sdpMid: sdpMid,
            sdpMLineIndex: sdpMLineIndex,
          ),
        // The peer leaving looks like a graceful close to the engine.
        PeerLeftFrame() => const SignalingMessage.bye(),
        _ => null,
      };

  SignalingFrame _toFrame(SignalingMessage message) => switch (message) {
    SignalingOffer(:final sdp) => RelayFrame(kind: RelayKind.offer, sdp: sdp),
    SignalingAnswer(:final sdp) => RelayFrame(kind: RelayKind.answer, sdp: sdp),
    SignalingIceCandidate(
      :final candidate,
      :final sdpMid,
      :final sdpMLineIndex,
    ) =>
      RelayFrame(
        kind: RelayKind.ice,
        candidate: candidate,
        sdpMid: sdpMid,
        sdpMLineIndex: sdpMLineIndex,
      ),
    SignalingBye() => const ByeFrame(),
  };
}
