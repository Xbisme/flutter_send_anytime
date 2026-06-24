import 'dart:async';
import 'dart:typed_data';

import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// An in-process [DataTransport] that models flow control, so the engine is
/// fully exercisable in CI without native WebRTC (FR-007, Constitution XII).
///
/// [deliveryLatency] simulates a slow link/consumer: while > 0, queued bytes
/// accumulate as [bufferedAmount], letting backpressure tests be deterministic.
class LoopbackDataTransport implements DataTransport {
  LoopbackDataTransport._(this.deliveryLatency);

  /// Create a connected pair of transports (sender side, receiver side).
  static (LoopbackDataTransport, LoopbackDataTransport) pair({
    Duration deliveryLatency = Duration.zero,
  }) {
    final a = LoopbackDataTransport._(deliveryLatency);
    final b = LoopbackDataTransport._(deliveryLatency);
    a._peer = b;
    b._peer = a;
    return (a, b);
  }

  /// Simulated per-message delivery latency (0 = immediate microtask delivery).
  final Duration deliveryLatency;

  final _inboundController = StreamController<Uint8List>();
  final _lowController = StreamController<void>.broadcast();
  final _closedCompleter = Completer<void>();

  late final LoopbackDataTransport _peer;
  var _bufferedAmount = 0;
  var _peakBufferedAmount = 0;
  var _lowThreshold = 0;
  var _closed = false;

  /// Highest [bufferedAmount] ever observed — asserted by the memory test.
  int get peakBufferedAmount => _peakBufferedAmount;

  @override
  Stream<Uint8List> get inbound => _inboundController.stream;

  @override
  int get bufferedAmount => _bufferedAmount;

  @override
  Stream<void> get onBufferedAmountLow => _lowController.stream;

  @override
  Future<void> get closed => _closedCompleter.future;

  @override
  void setBufferedAmountLowThreshold(int value) => _lowThreshold = value;

  @override
  Future<void> send(Uint8List data) async {
    if (_closed) throw StateError('transport closed');
    _bufferedAmount += data.length;
    if (_bufferedAmount > _peakBufferedAmount) {
      _peakBufferedAmount = _bufferedAmount;
    }
    // Copy so callers may reuse their buffer.
    final frame = Uint8List.fromList(data);
    Future<void> deliver() {
      if (_peer._closed || _peer._inboundController.isClosed) {
        return _drain(frame.length);
      }
      _peer._inboundController.add(frame);
      return _drain(frame.length);
    }

    if (deliveryLatency == Duration.zero) {
      scheduleMicrotask(deliver);
    } else {
      unawaited(Future<void>.delayed(deliveryLatency, deliver));
    }
  }

  Future<void> _drain(int length) async {
    final wasAbove = _bufferedAmount > _lowThreshold;
    _bufferedAmount -= length;
    if (wasAbove &&
        _bufferedAmount <= _lowThreshold &&
        !_lowController.isClosed) {
      _lowController.add(null);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    if (!_closedCompleter.isCompleted) _closedCompleter.complete();
    if (!_inboundController.isClosed) await _inboundController.close();
    if (!_lowController.isClosed) await _lowController.close();
  }

  /// Test affordance: simulate a hard link drop. The peer's transport observes
  /// its [closed] future complete and its inbound end (no cancel frame).
  void drop() {
    if (_closed) return;
    _closed = true;
    if (!_closedCompleter.isCompleted) _closedCompleter.complete();
    _peer._forceClose();
  }

  void _forceClose() {
    if (_closed) return;
    _closed = true;
    if (!_closedCompleter.isCompleted) _closedCompleter.complete();
    if (!_inboundController.isClosed) unawaited(_inboundController.close());
    if (!_lowController.isClosed) unawaited(_lowController.close());
  }
}

/// A [PeerConnector] for tests/in-process use: hands back a pre-wired loopback
/// transport, bypassing native WebRTC. Signaling is accepted but not required.
class LoopbackPeerConnector implements PeerConnector {
  LoopbackPeerConnector(this._transport);

  /// Build a connected pair of connectors (sender, receiver).
  static (LoopbackPeerConnector, LoopbackPeerConnector) pair({
    Duration deliveryLatency = Duration.zero,
  }) {
    final (a, b) = LoopbackDataTransport.pair(deliveryLatency: deliveryLatency);
    return (LoopbackPeerConnector(a), LoopbackPeerConnector(b));
  }

  final LoopbackDataTransport _transport;

  /// The underlying transport (tests inspect peak buffered amount / drop it).
  LoopbackDataTransport get transport => _transport;

  @override
  Future<Result<DataTransport>> connect({
    required TransferRole role,
    required SignalingChannel signaling,
    required List<RtcIceServer> iceServers,
    Duration timeout = const Duration(seconds: 30),
  }) async => Result<DataTransport>.success(_transport);
}
