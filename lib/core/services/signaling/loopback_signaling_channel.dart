import 'dart:async';

import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';

/// An in-process [SignalingChannel] that wires two engine instances together
/// directly, so the whole engine is testable without a server (FR-007).
class LoopbackSignalingChannel implements SignalingChannel {
  LoopbackSignalingChannel._(this._deliveryDelay);

  /// Create a connected pair of channels. A message sent on one is delivered to
  /// the other's [incoming] stream.
  static (LoopbackSignalingChannel, LoopbackSignalingChannel) pair({
    Duration deliveryDelay = Duration.zero,
  }) {
    final a = LoopbackSignalingChannel._(deliveryDelay)
      .._controller = StreamController<SignalingMessage>.broadcast();
    final b = LoopbackSignalingChannel._(deliveryDelay)
      .._controller = StreamController<SignalingMessage>.broadcast();
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  final Duration _deliveryDelay;
  late final StreamController<SignalingMessage> _controller;
  late final LoopbackSignalingChannel _peer;
  var _closed = false;

  @override
  Stream<SignalingMessage> get incoming => _controller.stream;

  @override
  Future<Result<void>> send(SignalingMessage message) async {
    if (_closed || _peer._closed) {
      return const Result.failure(AppFailure.networkError());
    }
    // Deliver asynchronously to mimic a real channel (never synchronous
    // re-entry). Late messages after the peer closes are dropped (FR-008).
    if (_deliveryDelay == Duration.zero) {
      scheduleMicrotask(() {
        if (!_peer._closed && !_peer._controller.isClosed) {
          _peer._controller.add(message);
        }
      });
    } else {
      unawaited(
        Future<void>.delayed(_deliveryDelay, () {
          if (!_peer._closed && !_peer._controller.isClosed) {
            _peer._controller.add(message);
          }
        }),
      );
    }
    return const Result.success(null);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _controller.close();
  }
}
