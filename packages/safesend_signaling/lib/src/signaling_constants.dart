/// Wire-protocol constants shared by the Safe Send app client and the relay.
///
/// Defined in exactly one place so the two programs can never drift
/// (Constitution VIII). Pure data — no Flutter, no third-party deps.
abstract final class SignalingProtocol {
  /// Current wire-protocol version. Frames with a different `v` are rejected.
  static const int version = 1;

  /// Number of digits in a pairing code.
  static const int codeLength = 6;

  /// Default time-to-live for an issued pairing code.
  static const Duration defaultTtl = Duration(minutes: 5);

  /// A valid 6-digit code: exactly six ASCII digits (leading zeros allowed).
  static final RegExp codePattern = RegExp(r'^\d{6}$');

  /// Whether [code] is a structurally valid pairing code.
  static bool isValidCode(String code) => codePattern.hasMatch(code);

  // --- frame `type` discriminators ---

  /// Sender → server: request a new room + code.
  static const String typeHost = 'host';

  /// Server → sender: room created; here is the code + TTL.
  static const String typeCodeIssued = 'code-issued';

  /// Receiver → server: join the room bound to a code.
  static const String typeJoin = 'join';

  /// Server → both: the peer is present (room full of its two participants).
  static const String typePeerJoined = 'peer-joined';

  /// Server → joiner: the code is valid but the room already has two peers.
  static const String typeRoomFull = 'room-full';

  /// Server → client: the code's TTL elapsed / room torn down.
  static const String typeCodeExpired = 'code-expired';

  /// Server → joiner: the code is unknown or malformed.
  static const String typeInvalidCode = 'invalid-code';

  /// Both: forward one SDP/ICE handshake item to the peer.
  static const String typeRelay = 'relay';

  /// Server → survivor: the other peer disconnected; room is gone.
  static const String typePeerLeft = 'peer-left';

  /// Client → server: graceful leave.
  static const String typeBye = 'bye';

  /// Server → client: too many invalid joins on this connection.
  static const String typeRateLimited = 'rate-limited';

  /// Server → client: ephemeral TURN relay credentials for this session
  /// (#014). Carries ICE-server *configuration* only (urls + short-lived
  /// username/credential) — connection-setup metadata, never file data. A
  /// client that predates this frame ignores the unknown type; a server that
  /// never sends it leaves the client on its static per-flavor ICE config
  /// (backward compatible).
  static const String typeTurnCredentials = 'turn-credentials';
}

/// The kind of handshake item carried by a relay frame. Maps 1:1 to the #002
/// `SignalingMessage` (`offer`/`answer`/`iceCandidate`).
enum RelayKind {
  /// An SDP offer.
  offer,

  /// An SDP answer.
  answer,

  /// A trickled ICE candidate.
  ice,
}
