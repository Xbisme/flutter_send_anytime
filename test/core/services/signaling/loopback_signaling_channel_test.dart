import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/signaling/loopback_signaling_channel.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';

void main() {
  test(
    'a message sent on one side is delivered to the other in order',
    () async {
      final (a, b) = LoopbackSignalingChannel.pair();
      final received = <SignalingMessage>[];
      final sub = b.incoming.listen(received.add);

      await a.send(const SignalingMessage.offer(sdp: 'o'));
      await a.send(
        const SignalingMessage.iceCandidate(candidate: 'c', sdpMLineIndex: 0),
      );
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        const SignalingMessage.offer(sdp: 'o'),
        const SignalingMessage.iceCandidate(candidate: 'c', sdpMLineIndex: 0),
      ]);
      await sub.cancel();
      await a.close();
      await b.close();
    },
  );

  test('send after close returns a failure result', () async {
    final (a, b) = LoopbackSignalingChannel.pair();
    await a.close();
    final result = await a.send(const SignalingMessage.bye());
    expect(result, isA<Failure<void>>());
    await b.close();
  });

  test('messages to a closed peer are dropped, not delivered', () async {
    final (a, b) = LoopbackSignalingChannel.pair();
    final received = <SignalingMessage>[];
    final sub = b.incoming.listen(received.add);
    await b.close();
    await a.send(const SignalingMessage.offer(sdp: 'late'));
    await Future<void>.delayed(Duration.zero);
    expect(received, isEmpty);
    await sub.cancel();
    await a.close();
  });
}
