# Contracts: Core Services (#011 Background Transfer)

**Date**: 2026-06-27. Dart interface contracts for the new `core/services/background/` components. These are the seams tested with fakes (Constitution XII); the real implementations wrap the two plugins. Signatures are illustrative (final names settled in tasks), not yet code.

---

## `BackgroundTransferCoordinator` (core, `@lazySingleton`)

The single orchestrator. Observes app lifecycle + the active transfer's snapshot stream; drives the platform controllers. Imports no features.

```dart
abstract class BackgroundTransferCoordinator {
  /// Published by a Send/Receive cubit when a transfer reaches `transferring`.
  /// Replaces any prior handle (single active transfer — FR-018).
  void attach(ActiveTransferHandle handle);

  /// Cleared by the cubit on terminal state, or internally on terminal snapshot.
  void detach();

  /// Wired to WidgetsBindingObserver; idempotent.
  void onAppLifecycleChanged(AppLifecycleState state);
}
```

**Behavioral contract**

- On `attach` + app already background + `phase == transferring` → start surface immediately.
- App → background while a `transferring` handle is attached → start surface.
- Each `TransferSnapshot` while surface is SHOWING → project to `BackgroundTransferState` → `controller.update(...)`.
- Terminal snapshot (`done/failed/cancelled`) → push final state → `controller.end(...)` → `detach`.
- App → foreground → `controller.end(...)` for any background-created surface (in-app screen takes over; same snapshots → already reconciled, FR-009).
- MUST NOT log peerName / byte values / file metadata (FR-014); MAY log surface-lifecycle phase + error-type.
- Selects the controller by platform: iOS → `LiveActivityController`; Android → `ForegroundServiceController`. (A no-op controller is used where unsupported, e.g. iOS < 16.1, so the rest degrades cleanly.)

---

## `LiveActivityController` (core, iOS) — wraps `live_activities`

```dart
abstract class LiveActivityController {
  Future<bool> get isSupported;                 // false on iOS < 16.1 → no-op surface
  Future<Result<void>> start(BackgroundTransferState state);
  Future<Result<void>> update(BackgroundTransferState state);
  Future<Result<void>> end();                    // settle to final + dismiss
}
```

- `start/update/end` are fallible (ActivityKit can refuse, e.g. too many activities, Live Activities disabled in Settings) → `Result<void>`; a failure degrades to "no rich surface", never blocks the transfer (FR-019 spirit).
- Pushes the `ContentState` defined in [live_activity_state.md](live_activity_state.md) into the App Group; the native Widget Extension renders it.
- `update` cadence throttled by the coordinator (≈ every 0.5–1 s or ≥1% delta — see quickstart), not per raw snapshot.

---

## `ForegroundServiceController` (core, Android) — wraps `flutter_foreground_task`

```dart
abstract class ForegroundServiceController {
  Future<Result<void>> start(BackgroundTransferState state); // start FGS + ongoing notification
  Future<Result<void>> update(BackgroundTransferState state); // update text + progress bar
  Future<Result<void>> end();                                 // stop service + remove notification
  Stream<BackgroundServiceAction> get actions;                // notification button events
}

enum BackgroundServiceAction { cancel } // "Huỷ" tapped
```

- `start` configures the ongoing (non-dismissible) notification: small icon, accent tint by direction, title/peerLine/meta from `state`, indeterminate-free **progress bar** (0–100), and one **Cancel ("Huỷ")** action button.
- `actions` emits `cancel` when the user taps "Huỷ" → coordinator invokes `handle.onCancel()` immediately (no confirm — Clarification), then the normal terminal snapshot ends the surface.
- Foreground service type = `dataSync`. If notification permission is denied, the OS-required service notice still posts where mandated; the transfer is never blocked (FR-019).
- The transfer keeps running on the **main isolate**; this controller only manages the service + notification (it does not run the transfer in the plugin's task isolate).

---

## Additive feature seam (Send / Receive cubits)

The **only** edits to merged feature code — additive, mirroring #006's `RecordTransferUseCase` injection:

- On entering `transferring`: build an `ActiveTransferHandle { snapshots, direction, peerName, fileCount, progressRoute, onCancel }` and call `coordinator.attach(handle)`.
- On terminal state (done/failed/cancelled) or page dispose: `coordinator.detach()`.
- `onCancel` calls the cubit's existing cancel method (the same one the in-app Danger "Hủy" button calls).

No other feature code changes. No engine/signaling/transport/protocol/DB edits.
