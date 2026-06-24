import 'package:web_socket_channel/web_socket_channel.dart';

/// A minimal text-frame WebSocket seam. The real implementation wraps
/// `web_socket_channel`; tests provide a fake so the client is exercised
/// without a live server.
abstract interface class SignalingSocket {
  /// Resolves when the socket is connected; throws/rejects on failure.
  Future<void> get ready;

  /// Inbound text frames from the relay.
  Stream<String> get incoming;

  /// Send a text frame to the relay.
  void send(String data);

  /// Close the socket (idempotent).
  Future<void> close();
}

/// Opens a [SignalingSocket] to the given endpoint. Injected so tests can swap
/// in a fake without a server.
typedef SignalingSocketOpener = SignalingSocket Function(Uri endpoint);

/// Real [SignalingSocket] backed by `web_socket_channel`.
class WebSocketSignalingSocket implements SignalingSocket {
  WebSocketSignalingSocket(this._channel);

  /// Connect to [endpoint] over WebSocket.
  factory WebSocketSignalingSocket.connect(Uri endpoint) =>
      WebSocketSignalingSocket(WebSocketChannel.connect(endpoint));

  final WebSocketChannel _channel;

  @override
  Future<void> get ready => _channel.ready;

  @override
  Stream<String> get incoming =>
      _channel.stream.map((event) => event is String ? event : '');

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() => _channel.sink.close();
}
