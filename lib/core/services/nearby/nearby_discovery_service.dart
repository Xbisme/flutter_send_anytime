import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/domain/result.dart';

/// Pure-core mDNS discovery seam for Nearby Radar (#009). Wraps the platform
/// service-discovery plugin; imports no features (Constitution XI). The 6-digit
/// #003 code rides in the advertised TXT record — signaling/transport unchanged.
abstract interface class NearbyDiscoveryService {
  /// Advertise this device on the local network carrying [code] in the TXT
  /// record. [displayName] becomes the human-recognizable service instance name.
  /// Returns `Result.failure(networkError)` if registration fails.
  Future<Result<void>> advertise({
    required String code,
    required String displayName,
  });

  /// Stop advertising (idempotent; safe if not advertising).
  Future<void> stopAdvertise();

  /// Browse + resolve nearby Safe Send advertisements as a live, self-updating
  /// list. Self-suppression is applied (our own advertisement is never listed,
  /// FR-004); the platform manages add/remove so stale entries drop off
  /// (SC-003). Emits `[]` when nobody is nearby. Adds an error to the stream if
  /// discovery cannot start.
  Stream<List<NearbyDevice>> discover();

  /// Stop browsing (idempotent). The consuming cubit calls this on close.
  Future<void> stopDiscover();
}
