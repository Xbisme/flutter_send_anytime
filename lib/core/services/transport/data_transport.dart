import 'dart:async';
import 'dart:typed_data';

import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';

/// An established, reliable, ordered byte pipe between the two peers — the
/// abstraction the engine sends/receives protocol frames over. Implemented by
/// the real WebRTC data channel and by an in-process loopback for tests.
abstract interface class DataTransport {
  /// Frames arriving from the peer, in order.
  Stream<Uint8List> get inbound;

  /// Send a framed message to the peer.
  Future<void> send(Uint8List data);

  /// Bytes queued but not yet flushed to the peer (flow control).
  int get bufferedAmount;

  /// Set the threshold below which [onBufferedAmountLow] fires.
  void setBufferedAmountLowThreshold(int value);

  /// Emits when [bufferedAmount] drops below the low-water threshold.
  Stream<void> get onBufferedAmountLow;

  /// Completes when the transport closes (locally or because the peer left).
  Future<void> get closed;

  /// Tear down the transport (idempotent).
  Future<void> close();
}

/// Optional capability (#014): a transport that can report whether ICE selected
/// a TURN-relayed path. Implemented by the real WebRTC transport only; the
/// engine treats any transport that is not [RelayAware] as direct (relay =
/// false), so loopback + test fakes need no change.
abstract interface class RelayAware {
  /// Whether the negotiated connection runs over a TURN relay.
  bool get isRelay;
}

/// Establishes a [DataTransport] between two peers. The engine depends on this
/// seam so it can run over real WebRTC in the app and over loopback in tests.
// ignore: one_member_abstracts
abstract interface class PeerConnector {
  /// Negotiate a connection in the given [role], exchanging SDP/ICE over
  /// [signaling]. Returns the connected transport or a typed failure.
  Future<Result<DataTransport>> connect({
    required TransferRole role,
    required SignalingChannel signaling,
    required List<RtcIceServer> iceServers,
    Duration timeout,
  });
}
