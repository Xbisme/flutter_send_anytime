import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/rate_limiter.dart';

/// The relay's minimal view of a connected peer. `RoomManager` depends on this
/// (not the concrete socket wrapper) so it is unit-testable with a fake.
abstract class Peer {
  /// The code of the room this peer hosts or has joined; null otherwise.
  abstract String? code;

  /// Per-connection rate limiter (FR-011a).
  RateLimiter get rateLimiter;

  /// Send a frame to this peer.
  void send(SignalingFrame frame);
}
