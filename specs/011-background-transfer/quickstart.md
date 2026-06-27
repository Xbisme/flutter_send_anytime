# Quickstart: Background Transfer (#011)

**Date**: 2026-06-27 · **Branch**: `011-background-transfer`

How to validate the feature, including the native pieces and the deferred two-device on-device smoke.

## Prerequisites

- `flutter pub get` after adding `live_activities ^2.4.9` + `flutter_foreground_task ^9.2.2`.
- First `pod install` (iOS) — `live_activities` pulls a pod and the Widget Extension target; **expect `ios/Podfile.lock` churn** (deferred to the device build, like prior native specs).
- Android: no Gradle/AGP churn expected (compileSdk 35 / AGP 8.11.1 already present); manifest gains the `<service>` + foreground-service permissions.

## CI-testable (no device)

Run on each change:

```bash
dart analyze lib test          # gate-equivalent (flutter analyze crashes on this checkout — project note)
flutter test                   # all pass, incl. new #011 tests
dart format --set-exit-if-changed .
```

New tests cover (Constitution XII — with fakes, no plugins/devices):

- **Snapshot → `BackgroundTransferState` projection**: send/receive accent + verb, percent/speed/bytes/ETA labels match the in-app `TransferProgressProjector`.
- **`BackgroundTransferCoordinator` lifecycle**: background-while-transferring starts a surface; each snapshot updates it; terminal snapshot ends + detaches; foreground return ends a background-created surface; rapid background/foreground toggles never create two surfaces (FR-018).
- **Cancel routing**: a fake `ForegroundServiceController.actions` emitting `cancel` invokes `handle.onCancel()` exactly once, immediately (no confirm — Clarification).
- **Degraded paths**: `LiveActivityController.isSupported == false` (iOS < 16.1) → coordinator no-ops the surface, transfer logic untouched; a `Result.failure` from `start()` does not block the transfer (FR-019 spirit).
- **Log hygiene**: coordinator/controllers emit no peerName / byte values / file metadata (Principle I / FR-014).
- **Send/Receive seam**: entering `transferring` calls `attach`; terminal/dispose calls `detach`; `onCancel` maps to the existing cubit cancel.

## Update-cadence guidance

The coordinator throttles surface updates to **≈ every 0.5–1 s or on ≥1% change**, whichever first (raw snapshots can be far more frequent). This keeps the Live Activity / notification smooth without thrashing ActivityKit or the notification manager. Verify in the coordinator test with a fake clock.

## Manual / device validation (DEFERRED — two-device smoke, Constitution XII)

Track in `tasks.md` banner; cannot be proven in CI.

**Android (sustained background — the guaranteed path, SC-001):**
1. Start a multi-file transfer (e.g. 200+ MB) device A → B.
2. On the **sending** device, background the app (Home) and lock the screen.
3. Confirm the ongoing notification shows live progress (title, peer, progress bar, mono meta) and that **the transfer continues to completion** while backgrounded the whole time.
4. Tap "Huỷ" mid-transfer on a fresh run → transfer cancels immediately on **both** peers, notification removed (SC-004).
5. Tap the notification body → app returns to the in-app progress screen for the same transfer (SC-006); no duplicate transfer.
6. On completion while backgrounded → notification settles to a final state and is cleaned up (SC-003).
7. Repeat with the **receiving** device backgrounded.

**iOS (display + clean-fail — scoped, SC-005):**
1. Start a transfer; background/lock on an iPhone with Dynamic Island (14 Pro+) running iOS 16.1+.
2. Confirm the Live Activity appears on the Lock Screen + Dynamic Island (compact/minimal; long-press → expanded) with correct direction accent + live fields.
3. **Short** transfer that finishes within the iOS grace window → completes; Live Activity settles + dismisses.
4. **Long** transfer left backgrounded past the grace window → on returning to the app, a clear interrupted-transfer message + **retry**; any fully-received files retained (partial); no stale Live Activity left showing (SC-005).
5. iOS < 16.1 / non-Dynamic-Island device → no crash, no dead surface; transfer behaves as before plus the existing #010 arrival notification where relevant.

## Definition of done (this spec)

- `dart analyze lib test` = 0 · `flutter test` all pass · `dart format` clean.
- New ARB (VI-first + EN) for all surface strings + interrupted-transfer copy, with `@description`.
- Android manifest: `<service>` + `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_DATA_SYNC` (POST_NOTIFICATIONS already present).
- iOS: Widget Extension target added; App Group configured; Info.plist `NSSupportsLiveActivities = YES`.
- `pubspec.lock` committed; `ios/Podfile.lock` churn noted (device build).
- Two-device background smoke tracked as deferred in `tasks.md`.
