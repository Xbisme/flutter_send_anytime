import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/peer.dart';
import 'package:server/rate_limiter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// One connected device's WebSocket, from the relay's perspective.
///
/// Holds the code of the room it currently hosts or has joined (null until it
/// hosts/joins), and its per-connection [rateLimiter]. Sends/encodes
/// [SignalingFrame]s; never inspects or stores SDP/ICE payloads.
class PeerConnection implements Peer {
  PeerConnection(this._channel, {RateLimiter? rateLimiter})
    : rateLimiter = rateLimiter ?? RateLimiter();

  final WebSocketChannel _channel;

  /// Guards this connection against code enumeration (FR-011a).
  @override
  final RateLimiter rateLimiter;

  /// The code of the room this connection hosts or has joined; null otherwise.
  @override
  String? code;

  var _closed = false;

  /// Send a frame to this peer (no-op once closed).
  @override
  void send(SignalingFrame frame) {
    if (_closed) return;
    _channel.sink.add(frame.encode());
  }

  /// Close the socket (idempotent).
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _channel.sink.close();
  }
}
