import 'dart:convert';

import 'package:safesend_signaling/src/signaling_constants.dart';

/// A single wire-protocol message exchanged over the signaling WebSocket.
///
/// Encodes to/decodes from versioned JSON text (`{"v":1,"type":...}`). There is
/// **structurally no frame field that carries file bytes** — this enforces the
/// "signaling never sees file data" promise by construction (Constitution I).
///
/// Decoding never throws: [tryDecode] returns `null` for anything malformed,
/// unknown, or version-mismatched. Validation happens here so both the relay
/// and the client share identical rules.
sealed class SignalingFrame {
  const SignalingFrame();

  /// This frame's `type` discriminator (one of `SignalingProtocol.type*`).
  String get type;

  /// JSON map representation, including the protocol version.
  Map<String, Object?> toJson();

  /// Encode to a JSON text frame ready to write to the socket.
  String encode() => jsonEncode(toJson());

  /// Decode a JSON text frame. Returns `null` for malformed JSON, a non-object
  /// payload, a version mismatch, an unknown type, or a missing/invalid field.
  static SignalingFrame? tryDecode(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, Object?>) return null;
    if (decoded['v'] != SignalingProtocol.version) return null;
    final type = decoded['type'];
    if (type is! String) return null;

    switch (type) {
      case SignalingProtocol.typeHost:
        return const HostFrame();
      case SignalingProtocol.typeCodeIssued:
        final code = decoded['code'];
        final ttl = decoded['ttlSeconds'];
        if (code is! String || !SignalingProtocol.isValidCode(code)) {
          return null;
        }
        if (ttl is! int) return null;
        return CodeIssuedFrame(code: code, ttlSeconds: ttl);
      case SignalingProtocol.typeJoin:
        final code = decoded['code'];
        if (code is! String || !SignalingProtocol.isValidCode(code)) {
          return null;
        }
        return JoinFrame(code: code);
      case SignalingProtocol.typePeerJoined:
        return const PeerJoinedFrame();
      case SignalingProtocol.typeRoomFull:
        return const RoomFullFrame();
      case SignalingProtocol.typeCodeExpired:
        return const CodeExpiredFrame();
      case SignalingProtocol.typeInvalidCode:
        return const InvalidCodeFrame();
      case SignalingProtocol.typeRelay:
        return _decodeRelay(decoded);
      case SignalingProtocol.typePeerLeft:
        return const PeerLeftFrame();
      case SignalingProtocol.typeBye:
        return const ByeFrame();
      case SignalingProtocol.typeRateLimited:
        final retry = decoded['retryAfterSeconds'];
        if (retry is! int) return null;
        return RateLimitedFrame(retryAfterSeconds: retry);
      default:
        return null;
    }
  }

  static SignalingFrame? _decodeRelay(Map<String, Object?> json) {
    final kindName = json['kind'];
    if (kindName is! String) return null;
    final kind = RelayKind.values.where((k) => k.name == kindName).firstOrNull;
    if (kind == null) return null;
    final sdp = json['sdp'];
    final candidate = json['candidate'];
    switch (kind) {
      case RelayKind.offer:
      case RelayKind.answer:
        if (sdp is! String) return null;
        return RelayFrame(kind: kind, sdp: sdp);
      case RelayKind.ice:
        if (candidate is! String) return null;
        final sdpMid = json['sdpMid'];
        final sdpMLineIndex = json['sdpMLineIndex'];
        return RelayFrame(
          kind: kind,
          candidate: candidate,
          sdpMid: sdpMid is String ? sdpMid : null,
          sdpMLineIndex: sdpMLineIndex is int ? sdpMLineIndex : null,
        );
    }
  }
}

extension<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

/// Sender → server: request a new room + code.
final class HostFrame extends SignalingFrame {
  const HostFrame();

  @override
  String get type => SignalingProtocol.typeHost;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Server → sender: room created; here is the code + remaining TTL (seconds).
final class CodeIssuedFrame extends SignalingFrame {
  const CodeIssuedFrame({required this.code, required this.ttlSeconds});

  final String code;
  final int ttlSeconds;

  @override
  String get type => SignalingProtocol.typeCodeIssued;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
    'code': code,
    'ttlSeconds': ttlSeconds,
  };
}

/// Receiver → server: join the room bound to [code].
final class JoinFrame extends SignalingFrame {
  const JoinFrame({required this.code});

  final String code;

  @override
  String get type => SignalingProtocol.typeJoin;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
    'code': code,
  };
}

/// Server → both: the peer is present (room now has its two participants).
final class PeerJoinedFrame extends SignalingFrame {
  const PeerJoinedFrame();

  @override
  String get type => SignalingProtocol.typePeerJoined;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Server → joiner: code valid but room already full.
final class RoomFullFrame extends SignalingFrame {
  const RoomFullFrame();

  @override
  String get type => SignalingProtocol.typeRoomFull;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Server → client: the code's TTL elapsed / room torn down.
final class CodeExpiredFrame extends SignalingFrame {
  const CodeExpiredFrame();

  @override
  String get type => SignalingProtocol.typeCodeExpired;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Server → joiner: the code is unknown or malformed.
final class InvalidCodeFrame extends SignalingFrame {
  const InvalidCodeFrame();

  @override
  String get type => SignalingProtocol.typeInvalidCode;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Both directions: forward one SDP/ICE handshake item to the peer.
final class RelayFrame extends SignalingFrame {
  const RelayFrame({
    required this.kind,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
  });

  final RelayKind kind;
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  @override
  String get type => SignalingProtocol.typeRelay;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
    'kind': kind.name,
    if (sdp != null) 'sdp': sdp,
    if (candidate != null) 'candidate': candidate,
    if (sdpMid != null) 'sdpMid': sdpMid,
    if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
  };
}

/// Server → survivor: the other peer disconnected; room is gone.
final class PeerLeftFrame extends SignalingFrame {
  const PeerLeftFrame();

  @override
  String get type => SignalingProtocol.typePeerLeft;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Client → server: graceful leave.
final class ByeFrame extends SignalingFrame {
  const ByeFrame();

  @override
  String get type => SignalingProtocol.typeBye;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
  };
}

/// Server → client: too many invalid joins on this connection.
final class RateLimitedFrame extends SignalingFrame {
  const RateLimitedFrame({required this.retryAfterSeconds});

  final int retryAfterSeconds;

  @override
  String get type => SignalingProtocol.typeRateLimited;

  @override
  Map<String, Object?> toJson() => {
    'v': SignalingProtocol.version,
    'type': type,
    'retryAfterSeconds': retryAfterSeconds,
  };
}
