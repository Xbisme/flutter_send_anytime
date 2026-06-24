import 'dart:async';
import 'dart:typed_data';

import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/loopback_signaling_channel.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/services/transport/loopback_data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_engine.dart';

/// Wraps a [DataTransport] and flips a byte in the Nth `chunk` frame it sends,
/// so the receiver's computed hash diverges → `integrityCheckFailed`.
class CorruptingTransport implements DataTransport {
  CorruptingTransport(this._inner, {this.corruptChunkIndex = 0});

  final DataTransport _inner;
  final int corruptChunkIndex;
  int _chunkSeen = 0;

  @override
  Future<void> send(Uint8List data) {
    if (data.isNotEmpty && data[0] == TransferOpcode.chunk && data.length > 1) {
      final isTarget = _chunkSeen == corruptChunkIndex;
      _chunkSeen++;
      if (isTarget) {
        final copy = Uint8List.fromList(data);
        copy[1] = copy[1] ^ 0xFF;
        return _inner.send(copy);
      }
    }
    return _inner.send(data);
  }

  @override
  Stream<Uint8List> get inbound => _inner.inbound;
  @override
  int get bufferedAmount => _inner.bufferedAmount;
  @override
  Stream<void> get onBufferedAmountLow => _inner.onBufferedAmountLow;
  @override
  Future<void> get closed => _inner.closed;
  @override
  void setBufferedAmountLowThreshold(int value) =>
      _inner.setBufferedAmountLowThreshold(value);
  @override
  Future<void> close() => _inner.close();
}

/// A connector that returns a fixed (possibly wrapped) transport.
class FixedPeerConnector implements PeerConnector {
  FixedPeerConnector(this._transport);
  final DataTransport _transport;

  @override
  Future<Result<DataTransport>> connect({
    required TransferRole role,
    required SignalingChannel signaling,
    required List<RtcIceServer> iceServers,
    Duration timeout = const Duration(seconds: 30),
  }) async => Result<DataTransport>.success(_transport);
}

/// A sender+receiver pair whose sender corrupts one chunk in flight.
class CorruptingHarness {
  CorruptingHarness({int corruptChunkIndex = 0}) {
    final (a, b) = LoopbackDataTransport.pair();
    final (ss, rs) = LoopbackSignalingChannel.pair();
    senderSignaling = ss;
    receiverSignaling = rs;
    const config = AppConfig(flavor: AppFlavor.dev);
    sender = TransferEngine(
      FixedPeerConnector(
        CorruptingTransport(a, corruptChunkIndex: corruptChunkIndex),
      ),
      config,
    );
    receiver = TransferEngine(FixedPeerConnector(b), config);
  }

  late final LoopbackSignalingChannel senderSignaling;
  late final LoopbackSignalingChannel receiverSignaling;
  late final TransferEngine sender;
  late final TransferEngine receiver;
}
