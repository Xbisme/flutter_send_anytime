import 'dart:async';
import 'dart:math';

import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/peer.dart';

/// One ephemeral rendezvous room: a host, an optional guest, and a TTL timer.
class _Room {
  _Room({required this.host});

  final Peer host;
  Peer? guest;
  Timer? expiry;
}

/// In-memory registry of pairing rooms — the heart of the relay.
///
/// Holds everything in a `Map` and nothing else: no database, no disk, no
/// retained metadata after a room ends (FR-015). Each room admits exactly two
/// peers and is discarded on expiry, disconnect, or both leaving (FR-013).
class RoomManager {
  RoomManager({
    this.ttl = SignalingProtocol.defaultTtl,
    Random? random,
  }) : _random = random ?? Random.secure();

  /// How long an issued code stays valid (configurable for tests).
  final Duration ttl;

  final Random _random;
  final Map<String, _Room> _rooms = <String, _Room>{};

  /// Number of live rooms — used by tests to assert no residue (SC-005).
  int get activeRoomCount => _rooms.length;

  /// Whether [code] currently maps to a live room.
  bool hasRoom(String code) => _rooms.containsKey(code);

  // --------------------------------------------------------------- hosting ---

  /// Create a room for [conn] and issue it a fresh 6-digit code.
  ///
  /// FR-006: a connection may hold only one active room — if [conn] already
  /// hosts/joined one, that room is torn down (its peer told `code-expired`)
  /// before the new code is issued.
  void host(Peer conn) {
    final existing = conn.code;
    if (existing != null) {
      _expireRoom(existing, except: conn);
      conn.code = null;
    }
    final code = _generateUniqueCode();
    _rooms[code] = _Room(host: conn)
      ..expiry = Timer(ttl, () => _expireRoom(code));
    conn
      ..code = code
      ..send(CodeIssuedFrame(code: code, ttlSeconds: ttl.inSeconds));
  }

  // ---------------------------------------------------------------- joining ---

  /// Join the room bound to [code]. Resolves to one of: paired (`peer-joined`
  /// to both), `room-full`, `invalid-code`/`code-expired`, or `rate-limited`.
  void join(Peer conn, String code) {
    final room = _rooms[code];
    if (room == null) {
      _registerInvalidJoin(conn);
      return;
    }
    if (room.guest != null || identical(room.host, conn)) {
      conn.send(const RoomFullFrame());
      return;
    }
    conn.rateLimiter.reset();
    room.guest = conn;
    conn.code = code;
    room.host.send(const PeerJoinedFrame());
    conn.send(const PeerJoinedFrame());
  }

  // ----------------------------------------------------------------- relay ---

  /// Forward a relay frame to the OTHER peer in [from]'s room (and no one
  /// else). The payload is never parsed or stored.
  void relay(Peer from, RelayFrame frame) {
    _peerOf(from)?.send(frame);
  }

  // ------------------------------------------------------------- lifecycle ---

  /// Graceful leave — identical to a disconnect (notify peer, drop room).
  void bye(Peer conn) => handleDisconnect(conn);

  /// A socket dropped: tear down its room and tell the survivor `peer-left`.
  void handleDisconnect(Peer conn) {
    final code = conn.code;
    if (code == null) return;
    final room = _rooms[code];
    if (room == null) {
      conn.code = null;
      return;
    }
    final other = identical(room.host, conn) ? room.guest : room.host;
    _removeRoom(code);
    other?.send(const PeerLeftFrame());
  }

  // --------------------------------------------------------------- helpers ---

  void _expireRoom(String code, {Peer? except}) {
    final room = _rooms[code];
    if (room == null) return;
    final host = room.host;
    final guest = room.guest;
    _removeRoom(code);
    if (!identical(host, except)) host.send(const CodeExpiredFrame());
    if (guest != null && !identical(guest, except)) {
      guest.send(const CodeExpiredFrame());
    }
  }

  void _removeRoom(String code) {
    final room = _rooms.remove(code);
    if (room == null) return;
    room.expiry?.cancel();
    if (room.host.code == code) room.host.code = null;
    if (room.guest?.code == code) room.guest?.code = null;
  }

  Peer? _peerOf(Peer conn) {
    final code = conn.code;
    if (code == null) return null;
    final room = _rooms[code];
    if (room == null) return null;
    if (identical(room.host, conn)) return room.guest;
    if (identical(room.guest, conn)) return room.host;
    return null;
  }

  void _registerInvalidJoin(Peer conn) {
    if (conn.rateLimiter.registerInvalidJoin()) {
      conn.send(
        RateLimitedFrame(retryAfterSeconds: conn.rateLimiter.retryAfterSeconds),
      );
    } else {
      conn.send(const InvalidCodeFrame());
    }
  }

  String _generateUniqueCode() {
    // Full 000000–999999 space, zero-padded (FR-002). Regenerate on collision.
    String next() => _random
        .nextInt(1000000)
        .toString()
        .padLeft(SignalingProtocol.codeLength, '0');
    var code = next();
    while (_rooms.containsKey(code)) {
      code = next();
    }
    return code;
  }
}
