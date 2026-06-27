import 'package:safe_send/core/services/background/background_transfer_state.dart';

/// User action delivered from a background surface (Android notification).
enum BackgroundServiceAction { cancel }

/// Platform abstraction over a single OS background surface — an iOS Live
/// Activity or an Android foreground-service notification. The coordinator
/// drives it; tests inject a fake.
///
/// Calls are best-effort: a failure degrades to "no rich surface" and is
/// logged, never thrown, so it can never block the underlying transfer
/// (FR-019 spirit). Mirrors the fire-and-forget shape of `IncomingFileNotifier`.
abstract interface class BackgroundSurfaceController {
  /// Whether this platform can show the surface right now (e.g. false on
  /// iOS < 16.1 → the coordinator no-ops the surface, transfer untouched).
  Future<bool> get isSupported;

  /// Start the surface for a freshly-backgrounded transfer.
  Future<void> start(BackgroundTransferState state);

  /// Update the live surface with a new projection.
  Future<void> update(BackgroundTransferState state);

  /// Settle to the final state and dismiss/clean up the surface.
  Future<void> end();

  /// Notification action taps (Android "Huỷ"). Empty on iOS.
  Stream<BackgroundServiceAction> get actions;
}
