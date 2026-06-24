import 'dart:math';

import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/peer.dart';
import 'package:server/rate_limiter.dart';
import 'package:server/room_manager.dart';
import 'package:test/test.dart';

/// Records the frames sent to a peer, for assertions.
class FakePeer implements Peer {
  FakePeer({RateLimiter? rateLimiter})
    : rateLimiter = rateLimiter ?? RateLimiter();

  @override
  String? code;

  @override
  final RateLimiter rateLimiter;

  final List<SignalingFrame> sent = <SignalingFrame>[];

  @override
  void send(SignalingFrame frame) => sent.add(frame);

  T last<T>() => sent.whereType<T>().last;
  bool has<T>() => sent.whereType<T>().isNotEmpty;
}

/// A deterministic [Random] that replays a fixed sequence of `nextInt` results.
class SeqRandom implements Random {
  SeqRandom(this._values);
  final List<int> _values;
  int _i = 0;

  @override
  int nextInt(int max) => _values[_i++ % _values.length];

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  group('hosting + happy-path join', () {
    test('host issues a 6-digit zero-padded code and opens one room', () {
      final rooms = RoomManager(random: SeqRandom([7]));
      final a = FakePeer();
      rooms.host(a);

      final issued = a.last<CodeIssuedFrame>();
      expect(issued.code, '000007'); // leading zeros preserved (FR-002)
      expect(SignalingProtocol.isValidCode(issued.code), isTrue);
      expect(a.code, '000007');
      expect(rooms.activeRoomCount, 1);
    });

    test('valid join notifies both peers and fills the room', () {
      final rooms = RoomManager(random: SeqRandom([1]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a)
        ..join(b, a.code!);

      expect(a.has<PeerJoinedFrame>(), isTrue);
      expect(b.has<PeerJoinedFrame>(), isTrue);
      expect(b.code, a.code);
    });

    test('generated codes are unique (collision regenerates)', () {
      final rooms = RoomManager(random: SeqRandom([5, 5, 6]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a) // 000005
        ..host(b); // collides on 5, regenerates to 6 -> 000006
      expect(a.last<CodeIssuedFrame>().code, '000005');
      expect(b.last<CodeIssuedFrame>().code, '000006');
      expect(rooms.activeRoomCount, 2);
    });
  });

  group('relay routing', () {
    test('forwards a relay frame only to the other peer', () {
      final rooms = RoomManager(random: SeqRandom([1]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a)
        ..join(b, a.code!)
        ..relay(a, const RelayFrame(kind: RelayKind.offer, sdp: 'o'));
      expect(b.has<RelayFrame>(), isTrue);
      expect(a.has<RelayFrame>(), isFalse); // never echoed back

      rooms.relay(b, const RelayFrame(kind: RelayKind.answer, sdp: 'a'));
      expect(a.last<RelayFrame>().kind, RelayKind.answer);
    });
  });

  group('failure paths', () {
    test('unknown code -> invalid-code', () {
      final rooms = RoomManager();
      final b = FakePeer();
      rooms.join(b, '424242');
      expect(b.has<InvalidCodeFrame>(), isTrue);
    });

    test('third peer -> room-full, existing pair undisturbed', () {
      final rooms = RoomManager(random: SeqRandom([1]));
      final a = FakePeer();
      final b = FakePeer();
      final c = FakePeer();
      rooms
        ..host(a)
        ..join(b, a.code!)
        ..join(c, a.code!);

      expect(c.has<RoomFullFrame>(), isTrue);
      expect(b.code, a.code); // b still in the room
      expect(rooms.activeRoomCount, 1);
    });

    test('FR-006: a second host invalidates the previous code', () {
      final rooms = RoomManager(random: SeqRandom([1, 2]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a) // 000001
        ..join(b, a.code!); // b joins room 1
      final firstCode = b.code!;

      rooms.host(a); // a hosts again -> room 1 torn down, new code 000002
      expect(b.has<CodeExpiredFrame>(), isTrue); // old guest told expired
      expect(rooms.hasRoom(firstCode), isFalse);
      expect(a.last<CodeIssuedFrame>().code, '000002');
      expect(rooms.activeRoomCount, 1);
    });

    test('rate limiting trips after repeated invalid joins', () {
      final rooms = RoomManager();
      final b = FakePeer(rateLimiter: RateLimiter(threshold: 2));
      for (var i = 0; i < 4; i++) {
        rooms.join(b, '000000');
      }
      expect(b.has<RateLimitedFrame>(), isTrue);
    });
  });

  group('TTL expiry', () {
    test('an unused code expires and leaves no residue', () async {
      final rooms = RoomManager(
        ttl: const Duration(milliseconds: 30),
        random: SeqRandom([1]),
      );
      final a = FakePeer();
      rooms.host(a);
      final code = a.code!;
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(a.has<CodeExpiredFrame>(), isTrue);
      expect(rooms.hasRoom(code), isFalse);
      expect(rooms.activeRoomCount, 0);
    });
  });

  group('lifecycle & statelessness (US3)', () {
    test('disconnect notifies the survivor and removes the room', () {
      final rooms = RoomManager(random: SeqRandom([1]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a)
        ..join(b, a.code!);
      final code = a.code!;

      rooms.handleDisconnect(a);
      expect(b.has<PeerLeftFrame>(), isTrue);
      expect(rooms.hasRoom(code), isFalse);
      expect(rooms.activeRoomCount, 0);

      // The code is now unusable (SC-005): a fresh join is invalid.
      final c = FakePeer();
      rooms.join(c, code);
      expect(c.has<InvalidCodeFrame>(), isTrue);
    });

    test('bye is a graceful leave; both leaving clears all state', () {
      final rooms = RoomManager(random: SeqRandom([1]));
      final a = FakePeer();
      final b = FakePeer();
      rooms
        ..host(a)
        ..join(b, a.code!)
        ..bye(a);
      expect(b.has<PeerLeftFrame>(), isTrue);
      rooms.bye(b); // no-op, already removed
      expect(rooms.activeRoomCount, 0);
    });
  });
}
