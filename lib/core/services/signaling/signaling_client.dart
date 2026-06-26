import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/signaling_endpoint_provider.dart';
import 'package:safe_send/core/constants/signaling_constants.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/signaling/signaling_socket.dart';
import 'package:safe_send/core/services/signaling/web_socket_signaling_channel.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

/// Owns one signaling WebSocket, drives the 6-digit pairing protocol, and
/// demultiplexes inbound frames: control frames advance [state]; `relay`
/// frames feed the produced [channel] (the #002 seam). One instance per pairing
/// attempt (`@injectable`). No file bytes ever cross it; logs phase/error only.
@injectable
class SignalingClient {
  SignalingClient(
    this._config, {
    SignalingSocketOpener? opener,
    SignalingEndpointProvider? endpointProvider,
  }) : _open = opener ?? WebSocketSignalingSocket.connect,
       _endpointProvider = endpointProvider;

  /// DI entry point: injectable builds the client from [config] +
  /// [endpointProvider] (the override-aware effective endpoint, #010), using the
  /// real WebSocket opener. Tests use the default constructor with a fake opener.
  @factoryMethod
  factory SignalingClient.create(
    AppConfig config,
    SignalingEndpointProvider endpointProvider,
  ) => SignalingClient(config, endpointProvider: endpointProvider);

  final AppConfig _config;
  final SignalingEndpointProvider? _endpointProvider;
  final SignalingSocketOpener _open;

  final _stateController = StreamController<PairingState>.broadcast();
  SignalingSocket? _socket;
  StreamSubscription<String>? _sub;
  WebSocketSignalingChannel? _channel;

  Completer<Result<PairingCode>>? _hostCompleter;
  Completer<Result<void>>? _joinCompleter;
  var _disposed = false;

  /// The pairing lifecycle stream (broadcast).
  Stream<PairingState> get state => _stateController.stream;

  /// The #002 signaling seam for this session. Valid once connected; the engine
  /// sends/receives SDP/ICE through it.
  SignalingChannel get channel =>
      _channel ??= WebSocketSignalingChannel(sendFrame: _sendFrame);

  /// Sender path: open the socket and request a 6-digit code.
  Future<Result<PairingCode>> host() async {
    final failure = await _connect();
    if (failure != null) return Result.failure(failure);
    final completer = _hostCompleter = Completer<Result<PairingCode>>();
    _send(const HostFrame());
    return completer.future.timeout(
      SignalingTimeouts.connect,
      onTimeout: () {
        _emitFailed(const AppFailure.signalingTimeout());
        return const Result.failure(AppFailure.signalingTimeout());
      },
    );
  }

  /// Receiver path: validate the code locally, open the socket, and join.
  Future<Result<void>> join(String code) async {
    if (!SignalingProtocol.isValidCode(code)) {
      _emitFailed(const AppFailure.invalidCode());
      return const Result.failure(AppFailure.invalidCode());
    }
    final failure = await _connect();
    if (failure != null) return Result.failure(failure);
    _emit(const PairingState.joining());
    final completer = _joinCompleter = Completer<Result<void>>();
    _send(JoinFrame(code: code));
    return completer.future.timeout(
      SignalingTimeouts.connect,
      onTimeout: () {
        _emitFailed(const AppFailure.signalingTimeout());
        return const Result.failure(AppFailure.signalingTimeout());
      },
    );
  }

  /// Graceful teardown: send `bye`, close the channel and socket (idempotent).
  ///
  /// The socket sink is closed BEFORE the stream subscription is cancelled, so
  /// the WebSocket close handshake can complete (cancelling first would hang
  /// `sink.close()`). A short timeout guards against an unresponsive peer.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_socket != null) {
      try {
        _send(const ByeFrame());
      } on Object {
        // best effort
      }
    }
    await _channel?.close();
    await _socket?.close().timeout(
      const Duration(seconds: 2),
      onTimeout: () {},
    );
    await _sub?.cancel();
    _emit(const PairingState.closed());
    if (!_stateController.isClosed) await _stateController.close();
  }

  // --------------------------------------------------------------- helpers ---

  Future<AppFailure?> _connect() async {
    final endpoint =
        _endpointProvider?.effective() ?? _config.signalingEndpoint;
    if (endpoint == null) {
      _emitFailed(const AppFailure.signalingUnreachable());
      return const AppFailure.signalingUnreachable();
    }
    _emit(const PairingState.connecting());
    // Opening a fresh socket immediately after a prior session closed can
    // momentarily fail (the OS/relay is still releasing the old connection), so
    // a single short-backoff retry recovers a new transfer right after one
    // finished. A genuinely unreachable endpoint still fails after the retry.
    for (var attempt = 0; attempt < 2; attempt++) {
      if (_disposed) return const AppFailure.signalingUnreachable();
      SignalingSocket? socket;
      try {
        socket = _open(endpoint);
        // Bound the connect so a dropped/blocked endpoint (e.g. iOS ATS blocking
        // cleartext ws:// to a LAN IP) surfaces as a failure instead of hanging.
        await socket.ready.timeout(SignalingTimeouts.connect);
        _socket = socket;
        _channel ??= WebSocketSignalingChannel(sendFrame: _sendFrame);
        _sub = socket.incoming.listen(
          _onData,
          onDone: _onSocketClosed,
          onError: (Object _) => _onSocketClosed(),
        );
        return null;
      } on Object catch (error) {
        AppLogger.error('signaling connect failed (${error.runtimeType})');
        if (socket != null) {
          unawaited(socket.close().catchError((Object _) {}));
        }
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        _emitFailed(const AppFailure.signalingUnreachable());
        return const AppFailure.signalingUnreachable();
      }
    }
    return const AppFailure.signalingUnreachable();
  }

  void _onData(String raw) {
    final frame = SignalingFrame.tryDecode(raw);
    if (frame == null) return;
    switch (frame) {
      case CodeIssuedFrame(:final code, :final ttlSeconds):
        final pairing = PairingCode.fromTtl(
          value: code,
          ttl: Duration(seconds: ttlSeconds),
        );
        _emit(PairingState.hosting(pairing));
        _completeHost(Result.success(pairing));
      case PeerJoinedFrame():
        _emit(const PairingState.peerPresent());
        _completeJoin(const Result.success(null));
      case RelayFrame():
        final message = WebSocketSignalingChannel.messageFromFrame(frame);
        if (message != null) _channel?.deliverFromPeer(message);
      case RoomFullFrame():
        _failPending(const AppFailure.roomFull());
      case InvalidCodeFrame():
        _failPending(const AppFailure.invalidCode());
      case CodeExpiredFrame():
        _failPending(const AppFailure.roomExpired());
      case RateLimitedFrame():
        _failPending(const AppFailure.rateLimited());
      case PeerLeftFrame():
        _channel?.deliverFromPeer(const SignalingMessage.bye());
        _failPending(const AppFailure.connectionLost());
      // Client never receives these from the server.
      case HostFrame():
      case JoinFrame():
      case ByeFrame():
        break;
    }
  }

  void _onSocketClosed() {
    if (_disposed) return;
    _failPending(const AppFailure.connectionLost());
  }

  void _completeHost(Result<PairingCode> result) {
    final completer = _hostCompleter;
    _hostCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  void _completeJoin(Result<void> result) {
    final completer = _joinCompleter;
    _joinCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete(result);
  }

  void _failPending(AppFailure failure) {
    _emitFailed(failure);
    _completeHost(Result.failure(failure));
    _completeJoin(Result.failure(failure));
  }

  void _send(SignalingFrame frame) => _socket?.send(frame.encode());

  void _sendFrame(SignalingFrame frame) => _send(frame);

  void _emit(PairingState state) {
    if (!_stateController.isClosed) _stateController.add(state);
  }

  void _emitFailed(AppFailure failure) => _emit(PairingState.failed(failure));
}
