import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:test/test.dart';

void main() {
  group('SignalingFrame round-trip', () {
    final frames = <SignalingFrame>[
      const HostFrame(),
      const CodeIssuedFrame(code: '012345', ttlSeconds: 300),
      const JoinFrame(code: '000000'),
      const PeerJoinedFrame(),
      const RoomFullFrame(),
      const CodeExpiredFrame(),
      const InvalidCodeFrame(),
      const RelayFrame(kind: RelayKind.offer, sdp: 'v=0\r\n'),
      const RelayFrame(kind: RelayKind.answer, sdp: 'v=0\r\n'),
      const RelayFrame(
        kind: RelayKind.ice,
        candidate: 'candidate:1 1 udp ...',
        sdpMid: '0',
        sdpMLineIndex: 0,
      ),
      const PeerLeftFrame(),
      const ByeFrame(),
      const RateLimitedFrame(retryAfterSeconds: 30),
    ];

    for (final frame in frames) {
      test('encodes and decodes ${frame.type}', () {
        final decoded = SignalingFrame.tryDecode(frame.encode());
        expect(decoded, isNotNull);
        expect(decoded!.encode(), frame.encode());
        expect(decoded.runtimeType, frame.runtimeType);
      });
    }

    test('ice relay preserves optional sdpMid/sdpMLineIndex', () {
      final decoded =
          SignalingFrame.tryDecode(
                const RelayFrame(
                  kind: RelayKind.ice,
                  candidate: 'c',
                  sdpMid: '1',
                  sdpMLineIndex: 2,
                ).encode(),
              )!
              as RelayFrame;
      expect(decoded.candidate, 'c');
      expect(decoded.sdpMid, '1');
      expect(decoded.sdpMLineIndex, 2);
    });

    test('code-issued preserves leading zeros', () {
      final decoded =
          SignalingFrame.tryDecode(
                const CodeIssuedFrame(code: '000007', ttlSeconds: 5).encode(),
              )!
              as CodeIssuedFrame;
      expect(decoded.code, '000007');
    });
  });

  group('SignalingFrame.tryDecode rejects invalid input', () {
    test('malformed JSON', () {
      expect(SignalingFrame.tryDecode('not json'), isNull);
    });

    test('non-object payload', () {
      expect(SignalingFrame.tryDecode('[]'), isNull);
      expect(SignalingFrame.tryDecode('42'), isNull);
    });

    test('version mismatch', () {
      expect(SignalingFrame.tryDecode('{"v":2,"type":"host"}'), isNull);
    });

    test('missing version', () {
      expect(SignalingFrame.tryDecode('{"type":"host"}'), isNull);
    });

    test('unknown type', () {
      expect(SignalingFrame.tryDecode('{"v":1,"type":"nope"}'), isNull);
    });

    test('join with non-6-digit code', () {
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"join","code":"12"}'),
        isNull,
      );
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"join","code":"abcdef"}'),
        isNull,
      );
      expect(SignalingFrame.tryDecode('{"v":1,"type":"join"}'), isNull);
    });

    test('code-issued missing ttl', () {
      expect(
        SignalingFrame.tryDecode(
          '{"v":1,"type":"code-issued","code":"012345"}',
        ),
        isNull,
      );
    });

    test('relay offer/answer missing sdp', () {
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"relay","kind":"offer"}'),
        isNull,
      );
    });

    test('relay ice missing candidate', () {
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"relay","kind":"ice"}'),
        isNull,
      );
    });

    test('relay with unknown kind', () {
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"relay","kind":"bogus"}'),
        isNull,
      );
    });

    test('rate-limited missing retryAfter', () {
      expect(
        SignalingFrame.tryDecode('{"v":1,"type":"rate-limited"}'),
        isNull,
      );
    });
  });

  group('protocol invariants', () {
    test('no frame carries a byte/binary field (privacy by construction)', () {
      // Every frame JSON is inspected: no key may hint at file payload.
      const forbidden = {'bytes', 'data', 'payload', 'chunk', 'file', 'blob'};
      final samples = <SignalingFrame>[
        const HostFrame(),
        const CodeIssuedFrame(code: '012345', ttlSeconds: 300),
        const JoinFrame(code: '012345'),
        const RelayFrame(kind: RelayKind.offer, sdp: 'v=0'),
        const RateLimitedFrame(retryAfterSeconds: 1),
      ];
      for (final f in samples) {
        expect(f.toJson().keys.toSet().intersection(forbidden), isEmpty);
      }
    });

    test('isValidCode', () {
      expect(SignalingProtocol.isValidCode('000000'), isTrue);
      expect(SignalingProtocol.isValidCode('999999'), isTrue);
      expect(SignalingProtocol.isValidCode('12345'), isFalse);
      expect(SignalingProtocol.isValidCode('1234567'), isFalse);
      expect(SignalingProtocol.isValidCode('12a456'), isFalse);
    });
  });
}
