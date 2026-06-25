# Phase 0 Research — #007 QR Connect

**Date**: 2026-06-25 · **Branch**: `007-qr-connect`
All package versions verified on pub.dev 2026-06-25 (Constitution XV).

## 1. Rendezvous reuse (no new transport)

- **Decision**: The 6-digit code IS the rendezvous identifier; the signaling room is keyed
  directly by it (confirmed in `packages/safesend_signaling/` + `SignalingClient`). QR only
  changes how that code is *exchanged*. No change to the engine (#002), signaling frames (#003),
  room keying, or the `PairingRepository.takeTransport()` seam.
- **Rationale**: Constitution VIII — every pairing method converges on one signaling/transport
  path. QR is a third presentation of the same `PairingHosting(code)` state.
- **Alternatives rejected**: encoding a separate room token in the QR (needs a protocol change,
  buys nothing — the code already keys the room).

## 2. Single hosting session across tabs (the core refactor)

- **Finding**: `_ConnectView.initState` already calls `host()` **once**, independent of the
  selected tab; the active code lives in the page-scoped `PairingCubit` (`PairingHosting.code`).
  Today only `_tab == 0` renders content; tabs 1/2 show `_ComingSoonTab`.
- **Decision**: Extend `_ConnectView` to render a **sender QR panel** for `_tab == 1` that reads
  the **same** `PairingHosting` state — no second `host()` call, no second socket. Switching tabs
  is pure UI; the code, TTL ticker, and in-flight pairing are untouched. This satisfies FR-004 by
  construction (there is only one session to begin with).
- **Rationale**: Lowest-risk path; the hosting lifecycle is already view-scoped. Avoids the
  classic bug of tab-mounted hosting that regenerates codes on switch.
- **Alternatives rejected**: hoisting `host()` into a per-tab widget (would risk multiple
  sessions); a `PageView`/`TabController` rewrite (unnecessary churn).

## 3. QR payload format & codec

- **Decision**: `safesend://connect?v=1&code=NNNNNN`. A pure-Dart **`ConnectLink` codec**
  (`build(code) → uri`, `parse(raw) → code | failure`) lives in `lib/core/domain/pairing/`
  (core, so #008 share-link reuses it; features can't own a core-shared contract — Constitution
  XI). Parse accepts only: scheme `safesend`, host/path `connect`, a known `v`, and a code passing
  `SignalingProtocol.isValidCode` (the one source of truth). Anything else → typed rejection.
- **Rationale**: Versioned + scheme-namespaced → distinguishable from foreign QR, deep-link-ready
  for #008 without re-encoding. Reusing `isValidCode` keeps validation single-sourced
  (Constitution VIII).
- **Alternatives rejected**: bare `"123456"` (collides with any numeric QR, not deep-link-ready);
  embedding the signaling endpoint (endpoint is per-flavor config — Principle VIII — redundant).
- **Scope guard**: #007 only *produces & parses* the URI in-app (camera/photo). OS-level deep
  linking (Associated Domains / App Links / `safesend://` external handler) is **#008**.

## 4. QR rendering

- **Decision**: `qr_flutter ^4.1.0` — `QrImageView(data: link, version: QrVersions.auto)`.
- **Platform**: pure-Dart painter, no native code → no pod/Podfile churn, no min-OS impact.
- **Theming**: render with design tokens (dark module on light card per palette); wrap in the
  existing card surface. A11y: the QR widget carries a `Semantics(label:)` announcing the code
  (FR-023).
- **Alternatives rejected**: hand-rolled painter (YAGNI); `pretty_qr_code` (heavier, unneeded).

## 5. QR scanning + pick-from-photo + torch

- **Decision**: `mobile_scanner ^7.2.0`.
  - Live scan: `MobileScanner(controller:)` with `onDetect`; debounce duplicate detections to a
    single join attempt (FR-014) via a "handled" latch on first valid parse.
  - Pick-from-photo: **reuse the already-present `file_picker ^11.0.2`** (image type) to get a
    file path, then `controller.analyzeImage(path)` to decode. Avoids adding `image_picker` and
    avoids a photo-library permission (document/photo picker needs none) — Constitution XIII.
  - Torch: `MobileScannerController(torchEnabled:)` + toggle button, shown only when supported
    (FR-017a).
- **Platform (verified, changelog)**: mobile_scanner **7.0.0 lowered iOS min from 15 → 12**;
  7.2.0 → **iOS 12.0**, **Android minSdk 23**, compileSdk 34. Project floor is **iOS 13.0 /
  Android 26** → **compatible, no bump**. Uses bundled MLKit on Android (app-size cost accepted;
  unbundled Play-Services variant not needed).
- **Lifecycle**: stop/dispose the controller on page dismiss + app background; resume on return
  (FR-017) — mirror the controller's `AppLifecycleListener` pattern from the package docs.
- **Alternatives rejected**: `qr_code_scanner` (unmaintained / Flutter-embedding issues);
  `google_mlkit_barcode_scanning` directly (more wiring, no Flutter camera preview widget).

## 6. Camera permission

- **Decision**: `permission_handler ^12.0.3` for explicit camera status + recovery — finally
  lands the dependency deferred since #004/#005.
  - `Permission.camera` → `request()` / `status` distinguishing `denied` / `permanentlyDenied` /
    `restricted` (FR-016); `openAppSettings()` for the blocked path.
  - Map to existing `AppFailure.permissionDenied` / `cameraUnavailable` (already in the sealed
    class, Constitution V) → localized via the failure mapper.
  - Pick-from-photo offered as the always-available fallback when the camera is blocked (FR-016).
- **Native config (verified, Constitution XV)**:
  - **iOS**: add `NSCameraUsageDescription` to both flavor Info.plists (VI primary string, EN);
    add the permission_handler **`PERMISSION_CAMERA=1`** macro in the Podfile `post_install`
    `GCC_PREPROCESSOR_DEFINITIONS` (permission_handler compiles only enabled permissions). First
    `pod install` will churn `ios/Podfile.lock` (expected; commit it).
  - **Android**: mobile_scanner contributes `<uses-permission CAMERA>`; permission_handler needs
    `compileSdk 35` — project uses `flutter.compileSdkVersion` (≥35 on the current Flutter
    toolchain) → verify at build, bump only if needed.
- **Alternatives rejected**: relying solely on mobile_scanner's internal permission flow (no
  clean `openAppSettings`, can't cleanly distinguish permanentlyDenied → can't satisfy FR-016).

## 7. Screen-brightness boost (FR-005a)

- **Decision**: `screen_brightness ^2.1.11` —
  `setApplicationScreenBrightness(1.0)` when the sender QR panel mounts/shows;
  `resetApplicationScreenBrightness()` on leave/dismiss/background. Plugin auto-restores on
  app-lifecycle end, a safety net against a stuck-bright screen.
- **Rationale**: Flutter has no built-in screen-brightness API; this is the standard plugin. The
  boost is a steady level change (no flashing) → consistent with Reduce-Motion/accessibility
  (FR-022/FR-005a).
- **Native config**: lightweight plugin; will add to `Podfile.lock` on first `pod install`
  (folds into the same on-device build as mobile_scanner/permission_handler).
- **Alternatives rejected**: a platform channel (reinvents the plugin); skipping the boost
  (clarification chose to include it for reliable scanning).

## 8. `pairingMethod = qr` threading (FR-018)

- **Finding**: `send_history_mapper.dart` and `receive_history_mapper.dart` currently **hardcode
  `PairingMethod.sixDigitCode`**; `ConnectResult` carries only the transport.
- **Decision**: add `PairingMethod method` to **`ConnectResult`** (core type). The Connect hub
  sets it at connect time:
  - **Sender**: `qr` if the QR tab is active when `PairingConnected` fires, else `sixDigitCode`.
  - **Receiver**: `qr` if the connection came through the scanner path, else `sixDigitCode`.
  Thread `result.method` from `send_selection_page` / `receive_entry_page` into the transfer
  cubit, and the mappers use it instead of the hardcoded constant (default stays `sixDigitCode`).
- **Rationale**: Additive, per-device "method I used" rule (per spec Assumptions) — testable and
  deterministic. No history schema change (enum value already reserved).
- **Alternatives rejected**: inferring method server-side (signaling carries no such data, and
  the two devices legitimately differ).

## 9. Navigation & entry points

- **Decision**:
  - New route `AppRoutes.qrScan` → a full-screen `QrScanPage` (pairing feature,
    `features/pairing/presentation/scan/`). It is **self-contained**: returns a parsed code
    (`String`) via `context.pop`; it does **not** depend on `PairingCubit`. The receiver panel
    then calls the existing `joinWithCode(code)` (reuse, no new join path).
  - `ConnectRequest` gains `bool openScanner` (default `false`). The receiver panel shows a
    **"Quét mã QR"** secondary button (Screen 04) that pushes `qrScan`; when `openScanner` is
    true the panel auto-pushes it once on first build.
  - **FR-019**: Home "Quét QR" quick action → `AppRoutes.receive` with
    `ConnectRequest(role: receiver, openScanner: true)` threaded so it lands directly on the
    scanner. (Today it pushes `/receive` with no flag.)
- **Rationale**: Keeping the scanner a separate route (not a Connect tab) matches the clarified
  decision and avoids mounting/unmounting a live camera on tab switches. The scanner staying
  cubit-free keeps it reusable and simple (Constitution XIII).

## 10. Testing strategy (Constitution XII)

- **Unit**: `ConnectLink` codec — round-trip build/parse, reject wrong scheme / unknown version /
  bad code / expired (parse is syntactic; expiry surfaces via the existing join path on a stale
  code).
- **Cubit (`bloc_test`)**: `QrScanCubit` permission states (granted / denied / permanentlyDenied /
  restricted), single-detection latch, analyzeImage success/no-code.
- **Widget**: sender QR panel renders a QR for the live code + shows readable digits; tab-switch
  keeps the same code (no extra `host()`); receiver panel shows "Quét mã QR"; scanner page
  permission-denied state shows Open-Settings + pick-from-photo.
- **Record mapping**: send & receive mappers emit `pairingMethod = qr` when `ConnectResult.method`
  is qr; default `sixDigitCode` preserved.
- **Camera/preview** themselves are **not** unit-testable → covered by the **two-physical-device
  smoke** (deferred, tracked in `tasks.md` banner): A shows QR → B scans → transfer → both records
  tagged `qr`; torch toggles; brightness boosts then restores.
