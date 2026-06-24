import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// Real [PeerConnector] backed by `flutter_webrtc`. Establishes an
/// `RTCPeerConnection` + ordered/reliable `RTCDataChannel`, exchanging SDP/ICE
/// over the injected [SignalingChannel]. DTLS encryption is always on and is
/// never weakened (Constitution II). Validated by the deferred two-device smoke
/// test — it cannot run in CI.
@LazySingleton(as: PeerConnector)
class WebRtcPeerConnector implements PeerConnector {
  @override
  Future<Result<DataTransport>> connect({
    required TransferRole role,
    required SignalingChannel signaling,
    required List<RtcIceServer> iceServers,
    Duration timeout = TransferConstants.kConnectTimeout,
  }) async {
    RTCPeerConnection? pc;
    StreamSubscription<SignalingMessage>? sub;
    try {
      pc = await createPeerConnection(<String, dynamic>{
        'iceServers': [
          for (final s in iceServers)
            <String, dynamic>{
              'urls': s.urls,
              if (s.username != null) 'username': s.username,
              if (s.credential != null) 'credential': s.credential,
            },
        ],
      });

      final channelCompleter = Completer<RTCDataChannel>();

      pc.onIceCandidate = (candidate) {
        unawaited(
          signaling.send(
            SignalingMessage.iceCandidate(
              candidate: candidate.candidate ?? '',
              sdpMid: candidate.sdpMid,
              sdpMLineIndex: candidate.sdpMLineIndex,
            ),
          ),
        );
      };

      void bindChannel(RTCDataChannel channel) {
        channel.onDataChannelState = (state) {
          if (state == RTCDataChannelState.RTCDataChannelOpen &&
              !channelCompleter.isCompleted) {
            channelCompleter.complete(channel);
          }
        };
        // Already-open channels (race) resolve immediately.
        if (channel.state == RTCDataChannelState.RTCDataChannelOpen &&
            !channelCompleter.isCompleted) {
          channelCompleter.complete(channel);
        }
      }

      if (role == TransferRole.sender) {
        final dc = await pc.createDataChannel(
          TransferConstants.kDataChannelLabel,
          RTCDataChannelInit()..ordered = true,
        );
        bindChannel(dc);
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        await signaling.send(SignalingMessage.offer(sdp: offer.sdp ?? ''));
      } else {
        pc.onDataChannel = bindChannel;
      }

      final pcRef = pc;
      sub = signaling.incoming.listen((message) {
        unawaited(_handleSignal(pcRef, role, message, signaling));
      });

      final channel = await channelCompleter.future.timeout(timeout);
      await sub.cancel();
      return Result<DataTransport>.success(
        _WebRtcDataTransport(pcRef, channel),
      );
    } on TimeoutException {
      await sub?.cancel();
      await pc?.close();
      return const Result.failure(AppFailure.peerUnreachable());
    } on Object catch (error) {
      // Log the error TYPE only — SDP/ICE errors can embed IP addresses.
      AppLogger.error('peer connect failed (${error.runtimeType})');
      await sub?.cancel();
      await pc?.close();
      return const Result.failure(AppFailure.iceFailed());
    }
  }

  Future<void> _handleSignal(
    RTCPeerConnection pc,
    TransferRole role,
    SignalingMessage message,
    SignalingChannel signaling,
  ) async {
    switch (message) {
      case SignalingOffer(:final sdp) when role == TransferRole.receiver:
        await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        await signaling.send(SignalingMessage.answer(sdp: answer.sdp ?? ''));
      case SignalingAnswer(:final sdp) when role == TransferRole.sender:
        await pc.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
      case SignalingIceCandidate(
        :final candidate,
        :final sdpMid,
        :final sdpMLineIndex,
      ):
        await pc.addCandidate(
          RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
        );
      case SignalingOffer():
      case SignalingAnswer():
      case SignalingBye():
        break;
    }
  }
}

class _WebRtcDataTransport implements DataTransport {
  _WebRtcDataTransport(this._pc, this._channel) {
    _channel.onMessage = (message) {
      if (message.isBinary) _inbound.add(message.binary);
    };
    _channel.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelClosed) {
        if (!_closed.isCompleted) _closed.complete();
      }
    };
    _channel.onBufferedAmountLow = (_) {
      if (!_low.isClosed) _low.add(null);
    };
  }

  final RTCPeerConnection _pc;
  final RTCDataChannel _channel;
  final _inbound = StreamController<Uint8List>();
  final _low = StreamController<void>.broadcast();
  final _closed = Completer<void>();
  var _isClosed = false;

  @override
  Stream<Uint8List> get inbound => _inbound.stream;

  @override
  int get bufferedAmount => _channel.bufferedAmount ?? 0;

  @override
  Stream<void> get onBufferedAmountLow => _low.stream;

  @override
  Future<void> get closed => _closed.future;

  @override
  void setBufferedAmountLowThreshold(int value) =>
      _channel.bufferedAmountLowThreshold = value;

  @override
  Future<void> send(Uint8List data) =>
      _channel.send(RTCDataChannelMessage.fromBinary(data));

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    if (!_closed.isCompleted) _closed.complete();
    await _channel.close();
    await _pc.close();
    await _inbound.close();
    await _low.close();
  }
}
