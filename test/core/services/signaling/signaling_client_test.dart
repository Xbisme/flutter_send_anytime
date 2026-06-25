import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/signaling/signaling_client.dart';
import 'package:safe_send/core/services/signaling/signaling_socket.dart';
import 'package:safe_send/core/services/signaling/web_socket_signaling_channel.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

class FakeSocket implements SignalingSocket {
  final _incoming = StreamController<String>.broadcast();
  final List<String> sent = <String>[];
  bool failReady = false;

  @override
  Future<void> get ready =>
      failReady ? Future<void>.error(StateError('refused')) : Future.value();

  @override
  Stream<String> get incoming => _incoming.stream;

  @override
  void send(String data) => sent.add(data);

  @override
  Future<void> close() async {}

  void emit(SignalingFrame frame) => _incoming.add(frame.encode());

  List<SignalingFrame> get sentFrames =>
      sent.map(SignalingFrame.tryDecode).whereType<SignalingFrame>().toList();
}

AppConfig _config() =>
    AppConfig(flavor: AppFlavor.dev, signalingEndpoint: Uri.parse('ws://x'));

void main() {
  group('WebSocketSignalingChannel mapping', () {
    test('send maps SignalingMessage → wire RelayFrame/ByeFrame', () async {
      final frames = <SignalingFrame>[];
      final channel = WebSocketSignalingChannel(sendFrame: frames.add);

      await channel.send(const SignalingMessage.offer(sdp: 'o'));
      await channel.send(const SignalingMessage.answer(sdp: 'a'));
      await channel.send(
        const SignalingMessage.iceCandidate(candidate: 'c', sdpMid: '0'),
      );
      await channel.send(const SignalingMessage.bye());

      expect(frames[0], isA<RelayFrame>());
      expect((frames[0] as RelayFrame).kind, RelayKind.offer);
      expect((frames[1] as RelayFrame).kind, RelayKind.answer);
      expect((frames[2] as RelayFrame).kind, RelayKind.ice);
      expect(frames[3], isA<ByeFrame>());
    });

    test('messageFromFrame maps relay/peer-left → SignalingMessage', () {
      expect(
        WebSocketSignalingChannel.messageFromFrame(
          const RelayFrame(kind: RelayKind.offer, sdp: 'o'),
        ),
        isA<SignalingOffer>(),
      );
      expect(
        WebSocketSignalingChannel.messageFromFrame(const PeerLeftFrame()),
        isA<SignalingBye>(),
      );
      expect(
        WebSocketSignalingChannel.messageFromFrame(const HostFrame()),
        isNull,
      );
    });

    test('deliverFromPeer surfaces on incoming', () async {
      final channel = WebSocketSignalingChannel(sendFrame: (_) {});
      final received = <SignalingMessage>[];
      channel.incoming.listen(received.add);
      channel.deliverFromPeer(const SignalingMessage.offer(sdp: 'o'));
      await Future<void>.delayed(Duration.zero);
      expect(received.single, isA<SignalingOffer>());
    });

    test('frames delivered BEFORE the listener attaches are buffered, '
        'not dropped, and replayed in order on subscribe', () async {
      // Regression: the connector subscribes only after `await
      // createPeerConnection()`; the peer's offer can be relayed during that
      // gap. A broadcast stream would drop it, stranding the handshake.
      final received = <SignalingMessage>[];
      WebSocketSignalingChannel(sendFrame: (_) {})
        ..deliverFromPeer(const SignalingMessage.offer(sdp: 'o'))
        ..deliverFromPeer(const SignalingMessage.iceCandidate(candidate: 'c'))
        ..incoming.listen(received.add);
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received[0], isA<SignalingOffer>());
      expect(received[1], isA<SignalingIceCandidate>());
    });
  });

  group('SignalingClient host', () {
    test('code-issued completes host() and emits hosting', () async {
      final socket = FakeSocket();
      final client = SignalingClient(_config(), opener: (_) => socket);
      final states = <PairingState>[];
      client.state.listen(states.add);

      final future = client.host();
      await pumpEventQueue();
      expect(socket.sentFrames.whereType<HostFrame>(), isNotEmpty);
      socket.emit(const CodeIssuedFrame(code: '012345', ttlSeconds: 300));
      final result = await future;

      expect(result, isA<Success<PairingCode>>());
      expect((result as Success<PairingCode>).value.value, '012345');
      expect(states.whereType<PairingHosting>(), isNotEmpty);
    });

    test('unreachable server → signalingUnreachable', () async {
      final socket = FakeSocket()..failReady = true;
      final client = SignalingClient(_config(), opener: (_) => socket);
      final result = await client.host();
      expect(result, isA<Failure<dynamic>>());
      expect(
        (result as Failure).failure,
        isA<AppFailureSignalingUnreachable>(),
      );
    });
  });

  group('SignalingClient join', () {
    test('peer-joined completes join() and emits peerPresent', () async {
      final socket = FakeSocket();
      final client = SignalingClient(_config(), opener: (_) => socket);
      final states = <PairingState>[];
      client.state.listen(states.add);

      final future = client.join('012345');
      await pumpEventQueue();
      socket.emit(const PeerJoinedFrame());
      final result = await future;

      expect(result, isA<Success<void>>());
      expect(states.whereType<PairingPeerPresent>(), isNotEmpty);
    });

    test(
      'locally-invalid code → invalidCode without a socket round-trip',
      () async {
        final socket = FakeSocket();
        final client = SignalingClient(_config(), opener: (_) => socket);
        final result = await client.join('12');
        expect((result as Failure).failure, isA<AppFailureInvalidCode>());
        expect(socket.sent, isEmpty);
      },
    );

    test('relay frames after pairing surface on the channel', () async {
      final socket = FakeSocket();
      final client = SignalingClient(_config(), opener: (_) => socket);
      final received = <SignalingMessage>[];
      client.channel.incoming.listen(received.add);

      final future = client.join('012345');
      await pumpEventQueue();
      socket.emit(const PeerJoinedFrame());
      await future;
      socket.emit(const RelayFrame(kind: RelayKind.offer, sdp: 'o'));
      await pumpEventQueue();

      expect(received.single, isA<SignalingOffer>());
    });
  });

  group('SignalingClient failure mapping (US2)', () {
    Future<AppFailure> joinThen(SignalingFrame failFrame) async {
      final socket = FakeSocket();
      final client = SignalingClient(_config(), opener: (_) => socket);
      final future = client.join('012345');
      await pumpEventQueue();
      socket.emit(failFrame);
      return ((await future) as Failure).failure;
    }

    test('room-full → roomFull', () async {
      expect(await joinThen(const RoomFullFrame()), isA<AppFailureRoomFull>());
    });
    test('invalid-code → invalidCode', () async {
      expect(
        await joinThen(const InvalidCodeFrame()),
        isA<AppFailureInvalidCode>(),
      );
    });
    test('code-expired → roomExpired', () async {
      expect(
        await joinThen(const CodeExpiredFrame()),
        isA<AppFailureRoomExpired>(),
      );
    });
    test('rate-limited → rateLimited', () async {
      expect(
        await joinThen(const RateLimitedFrame(retryAfterSeconds: 30)),
        isA<AppFailureRateLimited>(),
      );
    });
    test('peer-left → connectionLost', () async {
      expect(
        await joinThen(const PeerLeftFrame()),
        isA<AppFailureConnectionLost>(),
      );
    });
  });

  group('SignalingClient dispose', () {
    test('sends bye and is idempotent', () async {
      final socket = FakeSocket();
      final client = SignalingClient(_config(), opener: (_) => socket);
      final future = client.host();
      await pumpEventQueue();
      socket.emit(const CodeIssuedFrame(code: '012345', ttlSeconds: 300));
      await future;
      await client.dispose();
      await client.dispose(); // no throw
      expect(socket.sentFrames.whereType<ByeFrame>(), isNotEmpty);
    });
  });
}
