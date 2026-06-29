import 'package:flutter/services.dart';

/// Centralized haptic feedback for the key transfer moments (#014, FR-018).
///
/// Uses Flutter's built-in [HapticFeedback] — no package (Principle XIII). Each
/// call is best-effort and degrades gracefully: on a device without a taptic
/// engine, or with system haptics disabled, the platform simply no-ops, and any
/// channel error is swallowed so feedback never crashes a flow.
abstract final class Haptics {
  /// Connection established with the peer.
  static Future<void> connect() => _run(HapticFeedback.mediumImpact);

  /// Transfer completed successfully.
  static Future<void> complete() => _run(HapticFeedback.heavyImpact);

  /// Transfer failed.
  static Future<void> fail() => _run(HapticFeedback.vibrate);

  static Future<void> _run(Future<void> Function() effect) async {
    try {
      await effect();
    } on Object {
      // Never let haptics surface an error into a transfer flow.
    }
  }
}
