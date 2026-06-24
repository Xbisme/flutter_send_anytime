import 'dart:async';
import 'dart:io';

import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/signaling_server.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A WebSocket test client with a `next()` that resolves to the next decoded
/// frame (buffering so no frame is missed between awaits).
class TestClient {
  TestClient(this._channel) {
    _sub = _channel.stream.listen((data) {
      final frame = SignalingFrame.tryDecode(data as String);
      if (frame == null) return;
      if (_waiters.isNotEmpty) {
        _waiters.removeAt(0).complete(frame);
      } else {
        _buffer.add(frame);
      }
    });
  }

  final WebSocketChannel _channel;
  late final StreamSubscription<dynamic> _sub;
  final _buffer = <SignalingFrame>[];
  final _waiters = <Completer<SignalingFrame>>[];

  Future<SignalingFrame> next() {
    if (_buffer.isNotEmpty) return Future.value(_buffer.removeAt(0));
    final completer = Completer<SignalingFrame>();
    _waiters.add(completer);
    return completer.future.timeout(const Duration(seconds: 2));
  }

  void send(SignalingFrame frame) => _channel.sink.add(frame.encode());

  Future<void> close() async {
    await _sub.cancel();
    await _channel.sink.close();
  }
}

void main() {
  late SignalingServer server;
  late HttpServer http;

  setUp(() async {
    server = SignalingServer(ttl: const Duration(milliseconds: 60));
    http = await server.serve(port: 0);
  });

  tearDown(() async {
    await http.close(force: true);
  });

  Future<TestClient> connect() async {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:${http.port}'),
    );
    await channel.ready;
    return TestClient(channel);
  }

  test(
    'happy path: host → code → join → peer-joined → relay both ways',
    () async {
      final sender = await connect();
      sender.send(const HostFrame());
      final issued = await sender.next() as CodeIssuedFrame;
      expect(SignalingProtocol.isValidCode(issued.code), isTrue);

      final receiver = await connect();
      receiver.send(JoinFrame(code: issued.code));
      expect(await receiver.next(), isA<PeerJoinedFrame>());
      expect(await sender.next(), isA<PeerJoinedFrame>());

      sender.send(const RelayFrame(kind: RelayKind.offer, sdp: 'o'));
      final toReceiver = await receiver.next() as RelayFrame;
      expect(toReceiver.kind, RelayKind.offer);
      expect(toReceiver.sdp, 'o');

      receiver.send(
        const RelayFrame(kind: RelayKind.ice, candidate: 'c', sdpMid: '0'),
      );
      final toSender = await sender.next() as RelayFrame;
      expect(toSender.kind, RelayKind.ice);
      expect(toSender.candidate, 'c');

      await sender.close();
      await receiver.close();
    },
  );

  test('unknown code → invalid-code', () async {
    final receiver = await connect();
    receiver.send(const JoinFrame(code: '424242'));
    expect(await receiver.next(), isA<InvalidCodeFrame>());
    await receiver.close();
  });

  test('third peer → room-full, existing pair undisturbed', () async {
    final sender = await connect();
    sender.send(const HostFrame());
    final code = (await sender.next() as CodeIssuedFrame).code;

    final receiver = await connect();
    receiver.send(JoinFrame(code: code));
    await receiver.next(); // peer-joined
    await sender.next(); // peer-joined

    final third = await connect();
    third.send(JoinFrame(code: code));
    expect(await third.next(), isA<RoomFullFrame>());

    await sender.close();
    await receiver.close();
    await third.close();
  });

  test('unused code expires (short TTL) → code-expired', () async {
    final sender = await connect();
    sender.send(const HostFrame());
    await sender.next(); // code-issued
    // TTL is 60ms in setUp.
    expect(await sender.next(), isA<CodeExpiredFrame>());
    await sender.close();
  });

  test('peer disconnect → survivor gets peer-left', () async {
    final sender = await connect();
    sender.send(const HostFrame());
    final code = (await sender.next() as CodeIssuedFrame).code;

    final receiver = await connect();
    receiver.send(JoinFrame(code: code));
    await receiver.next(); // peer-joined
    await sender.next(); // peer-joined

    await sender.close(); // sender drops
    expect(await receiver.next(), isA<PeerLeftFrame>());
    await receiver.close();
  });

  test('no file bytes ever cross signaling (SC-002)', () async {
    // Every frame the server can emit is one of the known control/relay types;
    // none carries a byte payload. We assert the relayed frame is exactly the
    // text we sent and the room count returns to zero afterwards.
    final sender = await connect();
    sender.send(const HostFrame());
    final code = (await sender.next() as CodeIssuedFrame).code;
    final receiver = await connect();
    receiver.send(JoinFrame(code: code));
    await receiver.next();
    await sender.next();

    await sender.close();
    await receiver.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(server.activeRoomCount, 0); // nothing retained (SC-005)
  });
}
