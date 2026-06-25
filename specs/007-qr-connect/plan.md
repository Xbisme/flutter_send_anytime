# Implementation Plan: QR Connect

**Branch**: `007-qr-connect` | **Date**: 2026-06-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/007-qr-connect/spec.md`

## Summary

Add **QR-code pairing** as the second connection method, reusing the existing 6-digit signaling
rendezvous unchanged. The sender gets a **QR tab** in the Connect hub that renders the *live*
hosting code as a `safesend://connect?v=1&code=NNNNNN` QR (single hosting session shared with the
Mã 6 số tab — switching tabs never regenerates the code). The receiver gets a **full-screen scanner
page** (camera + pick-from-photo + torch) reached from a "Quét mã QR" button; a successful scan
returns the code and feeds the existing `joinWithCode` path straight into the #005 accept/reject
prompt. First real **camera permission** with graceful denial recovery. Transfers paired via QR are
tagged `pairingMethod = qr` (enum already reserved; no schema change). **No engine/signaling/
transport changes.**

## Technical Context

**Language/Version**: Dart `^3.11.0` / Flutter (current stable, per #001)
**Primary Dependencies (new, verified pub.dev 2026-06-25 — Constitution XV)**:
- `qr_flutter ^4.1.0` — QR render (`QrImageView`); pure-Dart, no native code.
- `mobile_scanner ^7.2.0` — camera scan + `analyzeImage(path)` + torch. **iOS 12.0 / Android
  minSdk 23** (≤ project floor iOS 13 / API 26 — compatible, no bump); compileSdk 34; bundled MLKit.
- `permission_handler ^12.0.3` — camera status (denied/permanentlyDenied/restricted) +
  `openAppSettings()`. Needs Android `compileSdk 35` (verify; project uses
  `flutter.compileSdkVersion`) and iOS Podfile `PERMISSION_CAMERA=1` macro. Lands the dependency
  deferred since #004/#005.
- `screen_brightness ^2.1.11` — `setApplicationScreenBrightness` / `resetApplicationScreenBrightness`
  for the QR-display boost (FR-005a), auto-reset on lifecycle.
**Reused (no new dep)**: `file_picker ^11.0.2` for pick-from-photo (image → path →
`analyzeImage`); avoids `image_picker` and a photo-library permission.
**Storage**: none new — `TransferRecord.pairingMethod` (drift, #006) already supports `qr`.
**Testing**: `flutter_test` + `bloc_test` + `mocktail` over loopback; camera/preview → deferred
two-device smoke.
**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+.
**Project Type**: Mobile app (Flutter, Clean Architecture + feature-first).
**Performance Goals**: receiver scan → accept prompt < 10 s (SC-001); single join per detection.
**Constraints**: privacy (QR = code+version only; no payload/code in logs); reuse the one
signaling/transport path; design-token + ARB + 4-state discipline.
**Scale/Scope**: one new tab panel, one new full-screen page + cubit, one core codec, two additive
core-type fields, ~4 native config edits.

## Constitution Check

*GATE: must pass before Phase 0 and after Phase 1. PASS unless noted.*

- **I/II Privacy & Data Minimization** — ✅ QR encodes only `version+code`; no bytes/identity;
  scanned payloads validated at the boundary (`ConnectLink.parse`); logs carry phase/error-type
  only (FR-024). No engine/signaling change → "no server holds data" untouched.
- **III BLoC 4-state** — ✅ new `QrScanCubit` is 4-state freezed; scanner side-effects via
  listeners; sender QR panel is a pure rebuild of the existing `PairingCubit` state (no new state).
- **IV/V Dart safety & Result** — ✅ codec + permission/scan ops return `Result<T>`; reuse
  `AppFailure.permissionDenied`/`cameraUnavailable`/`invalidCode`/`roomExpired`; no try/catch in
  cubits.
- **VI Design system** — ✅ tokens only; QR styled to palette; mono+tabular for the code; CTA/
  secondary pill conventions; Reduce-Motion respected (no scanner jank, steady brightness).
- **VII Cross-platform native** — ✅ contextual camera permission with graceful denial + Open
  Settings; iOS `NSCameraUsageDescription` + Podfile macro; Android CAMERA via plugin manifest;
  a11y labels; haptic on successful scan (reuse existing haptic util if present).
- **VIII Transport & Signaling** — ✅ pairing methods converge on one rendezvous; the 6-digit
  code stays the single identifier; `ConnectLink` is the single payload source of truth reusing
  `SignalingProtocol.isValidCode`. **No protocol/frame change.**
- **IX Reliability** — ✅ no transfer-path change; expired/foreign QR handled gracefully (reject +
  surface, never crash). No migration (no schema change).
- **X go_router** — ✅ new `AppRoutes.qrScan` constant; `context.push/pop` only; scanner validates
  payload before acting. (External `safesend://` deep-link handling is **#008**, out of scope.)
- **XI Feature-first** — ✅ `ConnectLink` + `ConnectRequest`/`ConnectResult` fields live in
  `core/`; scanner page is in `features/pairing/` and stays cubit-free of signaling; Home reaches
  receive via core-typed route extra (no feature→feature import).
- **XII Testing** — ✅ codec unit tests, `QrScanCubit` bloc tests, widget tests (QR panel,
  tab-switch invariance, scanner permission states), mapper tests; two-device smoke tracked
  (deferred).
- **XIII Simplicity/YAGNI** — ✅ reuse single hosting session, reuse `file_picker`, reuse
  `joinWithCode`; only 4 packages, each justified by a concrete FR. No deep-link infra (deferred
  #008).
- **XIV i18n** — ✅ all new copy in ARB (VI primary + EN) with `@description`; camera rationale,
  scan instructions, torch/pick labels, failure text.
- **XV Dependency hygiene** — ✅ versions verified on pub.dev today; native min-OS/SDK +
  permissions + Podfile macro documented in [research.md](research.md) before any Dart; caret
  constraints; lock files committed.

**No violations → Complexity Tracking omitted.**

## Project Structure

### Documentation (this feature)

```text
specs/007-qr-connect/
├── plan.md              # this file
├── research.md          # Phase 0 — package + refactor + permission decisions
├── data-model.md        # Phase 1 — ConnectLink, QrScanState, additive core fields
├── quickstart.md        # Phase 1 — CI gate + two-device smoke
├── contracts/
│   └── connect-link.md  # Phase 1 — QR payload URI + route/handoff contracts
├── checklists/
│   └── requirements.md  # spec quality checklist (from /speckit-specify)
└── tasks.md             # Phase 2 — /speckit-tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/app_routes.dart            # + AppRoutes.qrScan
│   ├── domain/pairing/
│   │   ├── connect_link.dart                # NEW — payload codec (shared w/ #008)
│   │   └── connect_handoff.dart             # + ConnectRequest.openScanner, ConnectResult.method
│   └── router/app_router.dart               # + qrScan route
├── features/
│   ├── pairing/presentation/
│   │   ├── connect/
│   │   │   ├── connect_page.dart            # render sender QR panel (tab 1); receiver "Quét mã QR" button; set ConnectResult.method
│   │   │   └── widgets/
│   │   │       ├── qr_display.dart          # NEW — QrImageView + readable code + brightness boost
│   │   │       └── code_input.dart          # (unchanged)
│   │   └── scan/                            # NEW
│   │       ├── qr_scan_page.dart            # NEW — full-screen scanner (camera + torch + pick-from-photo)
│   │       ├── cubit/qr_scan_cubit.dart     # NEW — 4-state permission/scan
│   │       └── cubit/qr_scan_state.dart     # NEW — QrScanView
│   ├── send/
│   │   ├── presentation/pages/send_selection_page.dart   # pass result.method onward
│   │   └── domain/send_history_mapper.dart               # use threaded method (not hardcoded)
│   ├── receive/
│   │   ├── presentation/pages/receive_entry_page.dart    # thread openScanner + result.method
│   │   └── domain/receive_history_mapper.dart            # use threaded method
│   └── home/presentation/widgets/home_sections.dart      # Quét QR → receive w/ openScanner:true
├── l10n/arb/                                # + QR/scan/permission strings (VI primary + EN)
└── core/di/…                                # register QrScanCubit (@injectable)

ios/Runner/*.plist + ios/Podfile             # NSCameraUsageDescription (per flavor) + PERMISSION_CAMERA macro
android/app/build.gradle.kts                 # verify compileSdk 35 (permission_handler)

test/
├── core/pairing/connect_link_test.dart      # codec acceptance matrix
├── features/pairing/qr_scan_cubit_test.dart  # permission states + single-detection latch
├── features/pairing/connect_qr_panel_test.dart # QR render + tab-switch invariance
├── features/pairing/qr_scan_page_test.dart   # denied → settings + pick-from-photo
└── features/{send,receive}/…_mapper_test.dart # pairingMethod = qr threading
```

**Structure Decision**: Pure extension of the existing pairing feature + two additive core seams
(`ConnectLink` codec; `ConnectRequest.openScanner` / `ConnectResult.method`). No new feature
module, no engine/signaling edits — mirrors how #004/#005/#006 added capability via additive core
types and the one-edit-to-merged-code pattern.

## Phase summary

- **Phase 0** ([research.md](research.md)) — DONE: packages + versions + native config verified;
  single-hosting-session refactor scoped; payload format; pick-from-photo via reused `file_picker`;
  `pairingMethod` threading.
- **Phase 1** ([data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)) —
  DONE: `ConnectLink` codec, `QrScanState`, additive core fields, route/handoff contracts, CI +
  two-device smoke.
- **Phase 2** — `/speckit-tasks` will derive the ordered task list (US1 receiver-scan + US2
  sender-QR as the P1 MVP slice; US3 pick-from-photo; US4 permission handling).

## Risks & mitigations

- **permission_handler Android compileSdk 35** → verify the toolchain's `flutter.compileSdkVersion`
  at build; bump only if needed. **iOS Podfile macro** is mandatory or the camera permission
  silently no-ops → captured in research + quickstart.
- **mobile_scanner controller lifecycle** (camera not released / "events after close") → follow the
  package's lifecycle pattern; stop+dispose on dismiss/background (FR-017).
- **Stuck-bright screen** → restore brightness on every exit path + rely on the plugin's lifecycle
  reset backstop.
- **Camera realities** (focus, low light, mirrored QR) → torch + pick-from-photo fallbacks; final
  proof is the deferred two-device smoke.
