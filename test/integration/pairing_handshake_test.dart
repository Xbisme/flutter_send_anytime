import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/signaling/signaling_client.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/data/pairing_repository_impl.dart';
import 'package:server/signaling_server.dart';

/// A stand-in for the real WebRTC connector that performs a minimal offer/answer
/// handshake *over the signaling channel* — proving SDP/ICE relay flows through
/// the real in-process relay end-to-end (the real WebRTC connect is the
/// deferred two-device smoke, T055).
class FakeHandshakeConnector implements PeerConnector {
  @override
  Future<Result<DataTransport>> connect({
    required TransferRole role,
    required SignalingChannel signaling,
    required List<RtcIceServer> iceServers,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final done = Completer<void>();
    final sub = signaling.incoming.listen((message) async {
      switch (message) {
        case SignalingOffer():
          await signaling.send(const SignalingMessage.answer(sdp: 'a'));
          if (!done.isCompleted) done.complete();
        case SignalingAnswer():
          if (!done.isCompleted) done.complete();
        case SignalingIceCandidate():
        case SignalingBye():
          break;
      }
    });
    if (role == TransferRole.sender) {
      await signaling.send(const SignalingMessage.offer(sdp: 'o'));
    }
    await done.future.timeout(timeout);
    await sub.cancel();
    return Result<DataTransport>.success(_FakeTransport());
  }
}

class _FakeTransport implements DataTransport {
  @override
  Stream<Uint8List> get inbound => const Stream<Uint8List>.empty();
  @override
  int get bufferedAmount => 0;
  @override
  Stream<void> get onBufferedAmountLow => const Stream<void>.empty();
  @override
  Future<void> get closed => Completer<void>().future;
  @override
  void setBufferedAmountLowThreshold(int value) {}
  @override
  Future<void> send(Uint8List data) async {}
  @override
  Future<void> close() async {}
}

void main() {
  late SignalingServer server;
  late HttpServer http;
  late AppConfig config;

  setUp(() async {
    server = SignalingServer(ttl: const Duration(seconds: 2));
    http = await server.serve(port: 0);
    config = AppConfig(
      flavor: AppFlavor.dev,
      signalingEndpoint: Uri.parse('ws://localhost:${http.port}'),
    );
  });

  tearDown(() async {
    await http.close(force: true);
  });

  PairingRepositoryImpl repo() => PairingRepositoryImpl(
    SignalingClient(config),
    FakeHandshakeConnector(),
    config,
    ActiveHostingRegistryImpl(),
  );

  test(
    'two clients pair via the real relay and reach connected (SC-006)',
    () async {
      final sender = repo();
      final receiver = repo();
      final senderConnected = sender.state.firstWhere(
        (s) => s is PairingConnected,
      );
      final receiverConnected = receiver.state.firstWhere(
        (s) => s is PairingConnected,
      );

      final hostResult = await sender.host();
      expect(hostResult, isA<Success<PairingCode>>());
      final code = (hostResult as Success<PairingCode>).value.value;
      expect(code.length, 6);

      await receiver.join(code);

      // Both reach connected only if the offer/answer relayed through the real
      // server. No file bytes ever cross signaling (SC-002 — the relay carries
      // only control/SDP frames, enforced structurally).
      await Future.wait([
        senderConnected,
        receiverConnected,
      ]).timeout(const Duration(seconds: 5));

      await sender.dispose();
      await receiver.dispose();
    },
  );

  test('joining with an unknown code fails (SC-003)', () async {
    final receiver = repo();
    final failed = receiver.state.firstWhere((s) => s is PairingFailed);
    await receiver.join('424242');
    final state = await failed.timeout(const Duration(seconds: 3));
    expect(state, isA<PairingFailed>());
    await receiver.dispose();
  });

  test('an unused code expires (SC-004)', () async {
    final sender = repo();
    final expired = sender.state.firstWhere((s) => s is PairingFailed);
    await sender.host();
    // Server TTL is 2s in setUp.
    final state = await expired.timeout(const Duration(seconds: 5));
    expect(state, isA<PairingFailed>());
    await sender.dispose();
  });

  test('mid-handshake disconnect notifies the survivor (SC-005)', () async {
    final sender = repo();
    final receiver = repo();
    final senderConnected = sender.state.firstWhere(
      (s) => s is PairingConnected,
    );
    final receiverConnected = receiver.state.firstWhere(
      (s) => s is PairingConnected,
    );

    final code = ((await sender.host()) as Success<PairingCode>).value.value;
    await receiver.join(code);
    await Future.wait([
      senderConnected,
      receiverConnected,
    ]).timeout(const Duration(seconds: 5));

    final receiverLost = receiver.state.firstWhere((s) => s is PairingFailed);
    await sender.dispose(); // sender drops
    final state = await receiverLost.timeout(const Duration(seconds: 3));
    expect(state, isA<PairingFailed>());
    await receiver.dispose();
  });
}
