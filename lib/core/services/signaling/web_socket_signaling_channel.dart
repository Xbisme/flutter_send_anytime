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
  // failure before peerPresent).
  final _inbound = StreamController<SignalingMessage>.broadcast();
  var _closed = false;

  // The connector subscribes to [incoming] only AFTER `await
  // createPeerConnection()` inside connect(). The peer's offer can be relayed
  // during that async gap; a broadcast stream drops events added with no
  // listener, which stranded the handshake (receiver never saw the offer). So we
  // buffer relay frames until the first listener attaches, then replay them in
  // order. After that, deliver straight through.
  final _pending = <SignalingMessage>[];
  var _hasListener = false;

  @override
  Stream<SignalingMessage> get incoming {
    _inbound.onListen = () {
      _hasListener = true;
      if (_pending.isEmpty) return;
      final buffered = List<SignalingMessage>.of(_pending);
      _pending.clear();
      for (final m in buffered) {
        if (!_inbound.isClosed) _inbound.add(m);
      }
    };
    return _inbound.stream;
  }

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
    // Before the connector subscribes, hold frames so the offer (relayed during
    // the connector's `await createPeerConnection`) isn't dropped; replayed by
    // [incoming]'s onListen. Once listening, deliver straight through.
    if (!_hasListener) {
      _pending.add(message);
      return;
    }
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
