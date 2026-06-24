import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/peer_connection.dart';
import 'package:server/rate_limiter.dart';
import 'package:server/room_manager.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Re-export so callers (bin, tests) can reference the shared protocol constants.
export 'package:safesend_signaling/safesend_signaling.dart'
    show SignalingProtocol;

/// The signaling relay: upgrades each request to a WebSocket, wraps it in a
/// [PeerConnection], and routes decoded [SignalingFrame]s through a shared
/// [RoomManager]. Carries SDP/ICE/control only — never file bytes. Holds no
/// state beyond the in-memory rooms and logs no payloads (FR-011/015/022).
class SignalingServer {
  SignalingServer({
    Duration ttl = SignalingProtocol.defaultTtl,
    this.rateLimit = const RateLimitConfig(),
    Random? random,
  }) : _rooms = RoomManager(ttl: ttl, random: random);

  final RoomManager _rooms;

  /// Per-connection rate-limit tuning (FR-011a).
  final RateLimitConfig rateLimit;

  /// Live room count (for tests / health).
  int get activeRoomCount => _rooms.activeRoomCount;

  /// The shelf handler — mount in any shelf pipeline or serve directly.
  Handler get handler =>
      webSocketHandler((webSocket, _) => _onConnect(webSocket));

  /// Bind and serve on [address]:[port].
  Future<HttpServer> serve({Object address = 'localhost', int port = 8080}) =>
      shelf_io.serve(handler, address, port);

  void _onConnect(WebSocketChannel webSocket) {
    final conn = PeerConnection(webSocket, rateLimiter: rateLimit.build());
    webSocket.stream.listen(
      (data) {
        // The protocol is text; ignore binary frames and anything malformed
        // (a defense against using signaling to smuggle data, FR-011).
        if (data is! String) return;
        final frame = SignalingFrame.tryDecode(data);
        if (frame == null) return;
        _dispatch(conn, frame);
      },
      onDone: () => _rooms.handleDisconnect(conn),
      onError: (Object _) => _rooms.handleDisconnect(conn),
      cancelOnError: true,
    );
  }

  void _dispatch(PeerConnection conn, SignalingFrame frame) {
    switch (frame) {
      case HostFrame():
        _rooms.host(conn);
      case JoinFrame(:final code):
        _rooms.join(conn, code);
      case RelayFrame():
        _rooms.relay(conn, frame);
      case ByeFrame():
        _rooms.bye(conn);
      // Server→client frames must never arrive from a client — ignore.
      case CodeIssuedFrame():
      case PeerJoinedFrame():
      case RoomFullFrame():
      case CodeExpiredFrame():
      case InvalidCodeFrame():
      case PeerLeftFrame():
      case RateLimitedFrame():
        break;
    }
  }
}
