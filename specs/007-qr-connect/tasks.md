---
description: "Task list for #007 QR Connect"
---

# Tasks: QR Connect

**Input**: Design documents from `/specs/007-qr-connect/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/connect-link.md](contracts/connect-link.md), [quickstart.md](quickstart.md)

**Tests**: INCLUDED — Constitution XII mandates unit tests for logic, `bloc_test` for all Cubits, and widget tests for transfer-critical flows.

**Organization**: Tasks are grouped by user story. US1 + US2 are both **P1** and together form the QR-pairing MVP. US3 + US4 are P2 hardening.

---

## ⚠️ Deferred / device-only tasks (track here per Constitution XII)

- **T041** Two-physical-device QR smoke (camera scan, torch, brightness, pick-from-photo, permission recovery) — cannot run in CI; see [quickstart.md](quickstart.md).
- **First `pod install`** after T001/T003 churns `ios/Podfile.lock` (mobile_scanner + permission_handler + screen_brightness pods) — folds into the next on-device build.
- **bloc-lint CLI** still uninstalled (tracked since #001) — gate step skipped, not failed.

> Quality gate per task group: `dart format .` · `dart analyze lib test` (0 issues — `flutter analyze` crashes on this checkout) · `flutter test`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add and natively configure the new dependencies (Constitution XV — versions verified pub.dev 2026-06-25 in research.md).

- [X] T001 Add packages to [pubspec.yaml](../../pubspec.yaml) with caret pins — `qr_flutter: ^4.1.0`, `mobile_scanner: ^7.2.0`, `permission_handler: ^12.0.3`, `screen_brightness: ^2.1.11` — then `flutter pub get`; commit `pubspec.lock`.
- [X] T002 [P] iOS: add `NSCameraUsageDescription` (VI primary string + EN) to [ios/Runner/Info.plist](../../ios/Runner/Info.plist) (and any per-flavor plist) explaining QR-scan camera use.
- [X] T003 [P] iOS: add the `PERMISSION_CAMERA=1` macro to `GCC_PREPROCESSOR_DEFINITIONS` in [ios/Podfile](../../ios/Podfile) `post_install` (permission_handler compiles only enabled permissions); note `pod install` deferred to device build.
- [X] T004 [P] Android: confirm `compileSdk` resolves to ≥35 for permission_handler in [android/app/build.gradle.kts](../../android/app/build.gradle.kts) (bump only if `flutter.compileSdkVersion` < 35); confirm mobile_scanner's `CAMERA` permission is present (plugin-contributed) incl. the dev-flavor manifest.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared payload codec, route, core handoff fields, and ARB copy that every story depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T005 [P] Create the `ConnectLink` codec (`build`/`parse`, version 1, reuse `SignalingProtocol.isValidCode`, return `Result<String>`) in [lib/core/domain/pairing/connect_link.dart](../../lib/core/domain/pairing/connect_link.dart) per [contracts/connect-link.md](contracts/connect-link.md).
- [X] T006 [P] Unit test the `ConnectLink` acceptance matrix (valid round-trip; reject wrong scheme / wrong target / unknown version / bad code / arbitrary text / empty) in [test/core/pairing/connect_link_test.dart](../../test/core/pairing/connect_link_test.dart).
- [X] T007 Add `static const qrScan = '/qr/scan';` to [lib/core/constants/app_routes.dart](../../lib/core/constants/app_routes.dart).
- [X] T008 Add additive fields to the core handoff types in [lib/core/domain/pairing/connect_handoff.dart](../../lib/core/domain/pairing/connect_handoff.dart): `ConnectRequest.openScanner` (bool, default false) and `ConnectResult.method` (`PairingMethod`, default `sixDigitCode`).
- [X] T009 Register the `AppRoutes.qrScan` full-screen route (→ `QrScanPage`) in [lib/core/router/app_router.dart](../../lib/core/router/app_router.dart) (nav-less flow route; `context.push<String>`).
- [X] T010 [P] Add all #007 ARB strings (VI primary + EN, with `@description`) to [lib/l10n/arb/app_vi.arb](../../lib/l10n/arb/app_vi.arb) + [lib/l10n/arb/app_en.arb](../../lib/l10n/arb/app_en.arb): scan title/instruction, "Quét mã QR" button, torch on/off, pick-from-photo, camera-rationale, camera-blocked + Open Settings, "not a Safe Send code", "expired code"; keep key parity.

**Checkpoint**: Codec + route + handoff + copy ready — stories can proceed.

---

## Phase 3: User Story 1 — Receiver scans the sender's QR (Priority: P1) 🎯 MVP

**Goal**: A receiver opens the scanner, points at a valid Safe Send QR, and auto-joins the room into the accept/reject prompt — no typing.

**Independent Test**: With any device displaying a valid pairing code's QR, open Nhận → Quét mã QR → scan → device reaches the incoming-transfer prompt, identical to manual entry.

### Tests for User Story 1 ⚠️

- [X] T011 [P] [US1] `bloc_test` for `QrScanCubit`: permission-granted → camera-ready; a valid detection parses + latches to a single result; a foreign/unparseable QR keeps `loaded` (no terminal error) in [test/features/pairing/qr_scan_cubit_test.dart](../../test/features/pairing/qr_scan_cubit_test.dart). _(Shared file with T027/T030/T035 — `[P]` only vs other-file tasks; serialize these four with each other.)_
- [X] T012 [P] [US1] Widget test: receiver panel renders the "Quét mã QR" button; tapping pushes `AppRoutes.qrScan`; a returned code triggers `joinWithCode` in [test/features/pairing/connect_receiver_scan_test.dart](../../test/features/pairing/connect_receiver_scan_test.dart).

### Implementation for User Story 1

- [X] T013 [P] [US1] Create `QrScanState`/`QrScanView` (freezed: `permission`, `torchOn`, `handled`) + `CameraPermissionStatus` enum in [lib/features/pairing/presentation/scan/cubit/qr_scan_state.dart](../../lib/features/pairing/presentation/scan/cubit/qr_scan_state.dart).
- [X] T014 [US1] Create `QrScanCubit` (`@injectable`, 4-state): request camera permission, expose torch, on detection `ConnectLink.parse` → latch (FR-014) → surface foreign QR via `AppFailure.invalidCode` without leaving `loaded` (FR-012) in [lib/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart](../../lib/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart).
- [X] T015 [US1] Create `QrScanPage` (full-screen): `MobileScanner` preview + `onDetect` → cubit; granted path; **torch toggle button** wired to `QrScanView.torchOn` (shown only when supported — FR-017a); on valid code `context.pop<String>(code)`; foreign QR → non-blocking toast (`AppToast`); haptic on success in [lib/features/pairing/presentation/scan/qr_scan_page.dart](../../lib/features/pairing/presentation/scan/qr_scan_page.dart).
- [X] T016 [US1] Run codegen (`dart run build_runner build --delete-conflicting-outputs`) and register `QrScanCubit` in DI ([lib/core/di/injection.config.dart](../../lib/core/di/injection.config.dart) regenerated).
- [X] T017 [US1] In [lib/features/pairing/presentation/connect/connect_page.dart](../../lib/features/pairing/presentation/connect/connect_page.dart) `_ReceiverPanel`: add the "Quét mã QR" `SecondaryButton` (Screen 04) → push `qrScan`; on returned code call existing `PairingCubit.joinWithCode`; auto-open once when `ConnectRequest.openScanner` is true. The button MUST remain available on the failure state, so a scanned→expired code can be re-scanned (this is the FR-013 retry path).
- [X] T018 [US1] In `connect_page.dart` set `ConnectResult.method = qr` for the receiver when the connection came via the scanner path (else `sixDigitCode`).
- [X] T019 [US1] Thread `result.method` from [lib/features/receive/presentation/pages/receive_entry_page.dart](../../lib/features/receive/presentation/pages/receive_entry_page.dart) into the receive transfer flow, and consume it in [lib/features/receive/domain/receive_history_mapper.dart](../../lib/features/receive/domain/receive_history_mapper.dart) (replace hardcoded `sixDigitCode`); update [test/features/receive/receive_history_mapper_test.dart](../../test/features/receive/receive_history_mapper_test.dart) for `qr`.
- [X] T020 [US1] Wire the Home "Quét QR" quick action → `AppRoutes.receive` with `ConnectRequest(role: receiver, openScanner: true)` in [lib/features/home/presentation/widgets/home_sections.dart](../../lib/features/home/presentation/widgets/home_sections.dart) (FR-019).

**Checkpoint**: Receiver can scan any valid Safe Send QR and reach the accept/reject prompt; QR-paired receives are tagged `qr`.

---

## Phase 4: User Story 2 — Sender presents the connection as a QR (Priority: P1) 🎯 MVP

**Goal**: The sender's Connect-hub QR tab shows a scannable QR for the *live* code (+ readable digits), sharing the single hosting session.

**Independent Test**: Send → Connect → QR tab → the QR decodes to `safesend://connect?v=1&code=<live code>`; readable digits match; switching Mã 6 số ↔ QR never changes the code.

### Tests for User Story 2 ⚠️

- [X] T021 [P] [US2] Widget test: sender QR panel renders a `QrImageView` for the live code + the readable code; switching tabs keeps the same code and does NOT trigger a second `host()` (FR-004) in [test/features/pairing/connect_qr_panel_test.dart](../../test/features/pairing/connect_qr_panel_test.dart).

### Implementation for User Story 2

- [X] T022 [P] [US2] Create `QrDisplay` widget: `QrImageView(ConnectLink.build(code))` styled to design tokens + readable code (mono/tabular) + `Semantics` announcing the code (FR-023) in [lib/features/pairing/presentation/connect/widgets/qr_display.dart](../../lib/features/pairing/presentation/connect/widgets/qr_display.dart).
- [X] T023 [US2] Add the screen-brightness boost on show / restore on hide+dispose+background (`screen_brightness`, steady level, no flashing — FR-005a) to `QrDisplay`.
- [X] T024 [US2] In [lib/features/pairing/presentation/connect/connect_page.dart](../../lib/features/pairing/presentation/connect/connect_page.dart): render the sender `QrDisplay` panel for `_tab == 1` reading the SAME `PairingHosting` state (no new `host()`, no second socket — FR-004); QR refreshes when the code rotates (FR-005); **in the receiver role omit the QR segment from `SegmentedTabs` entirely** (role-dependent segment list) so there is no scanner tab (FR-001 sender-only) — receivers scan via the T017 button, not a tab.
- [X] T025 [US2] In `connect_page.dart` set `ConnectResult.method = qr` for the sender when the QR tab is active at `PairingConnected` (else `sixDigitCode`).
- [X] T026 [US2] Thread `result.method` from [lib/features/send/presentation/pages/send_selection_page.dart](../../lib/features/send/presentation/pages/send_selection_page.dart) into the send transfer flow, and consume it in [lib/features/send/domain/send_history_mapper.dart](../../lib/features/send/domain/send_history_mapper.dart) (replace hardcoded `sixDigitCode`); update [test/features/send/send_history_mapper_test.dart](../../test/features/send/send_history_mapper_test.dart) for `qr`.

**Checkpoint**: MVP complete — A shows QR, B scans, transfer runs, both records tagged `qr` for the device that used QR.

---

## Phase 5: User Story 3 — Scan a QR image from the photo library (Priority: P2)

**Goal**: The receiver decodes a QR from an existing image instead of the live camera.

**Independent Test**: From the scanner, pick a saved QR image → decodes the same payload → joins the room; an image with no/foreign QR → "no valid code found", stays on scanner.

### Tests for User Story 3 ⚠️

- [X] T027 [US3] `bloc_test` for `QrScanCubit.analyzeImage`: valid image → code returned; no-code/foreign image → non-blocking failure, stays `loaded` in [test/features/pairing/qr_scan_cubit_test.dart](../../test/features/pairing/qr_scan_cubit_test.dart). _(Same file as T011/T030/T035 — not `[P]`.)_

### Implementation for User Story 3

- [X] T028 [US3] Add a pick-from-photo action to `QrScanCubit`/`QrScanPage`: reuse `file_picker` (image) → path → `MobileScannerController.analyzeImage(path)` → `ConnectLink.parse` → same latch/return; no new photo-library permission in [lib/features/pairing/presentation/scan/qr_scan_page.dart](../../lib/features/pairing/presentation/scan/qr_scan_page.dart).
- [X] T029 [US3] Surface "no valid code found" via `AppToast` and keep the scanner open on a no-QR/foreign image (FR-012) in `qr_scan_page.dart`.

**Checkpoint**: Pick-from-photo joins identically to a live scan and is available even when the camera is blocked.

---

## Phase 6: User Story 4 — Camera permission handled gracefully (Priority: P2)

**Goal**: Every camera-permission state (granted/denied/restricted/permanently-denied) has clear copy and an actionable next step; a denial never dead-ends.

**Independent Test**: Drive each permission state → granted starts camera; permanently-denied shows Open Settings + pick-from-photo (no blank preview); granted-again reopens with no prompt.

### Tests for User Story 4 ⚠️

- [X] T030 [US4] `bloc_test` for `QrScanCubit` permission mapping: `denied` / `permanentlyDenied` / `restricted` → correct `CameraPermissionStatus` + localized failure in [test/features/pairing/qr_scan_cubit_test.dart](../../test/features/pairing/qr_scan_cubit_test.dart). _(Same file as T011/T027/T035 — not `[P]`.)_
- [X] T031 [P] [US4] Widget test: scanner page in `permanentlyDenied` shows an **Open Settings** action + pick-from-photo (not a dead preview) in [test/features/pairing/qr_scan_page_test.dart](../../test/features/pairing/qr_scan_page_test.dart).

### Implementation for User Story 4

- [X] T032 [US4] Map `permission_handler` `PermissionStatus` → `CameraPermissionStatus` and to `AppFailure.permissionDenied`/`cameraUnavailable` (localized) in [lib/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart](../../lib/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart) (FR-015/016).
- [X] T033 [US4] Add the blocked-camera UI to `QrScanPage`: rationale + **Open Settings** (`openAppSettings()`) + pick-from-photo fallback (FR-016) in [lib/features/pairing/presentation/scan/qr_scan_page.dart](../../lib/features/pairing/presentation/scan/qr_scan_page.dart).
- [X] T034 [US4] Add scanner lifecycle handling: stop/dispose the controller on dismiss + app background, resume cleanly on return (FR-017) in `qr_scan_page.dart`.

**Checkpoint**: No permission state blocks pairing; camera is released/resumed correctly.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T035 Verify the expired/stale QR path: a well-formed but expired scanned code passes `ConnectLink.parse` then surfaces `roomExpired` via the existing join path, and the "Quét mã QR" button stays available for a re-scan (the retry path — see T017); no duplicate expiry logic — add/adjust assertion in [test/features/pairing/qr_scan_cubit_test.dart](../../test/features/pairing/qr_scan_cubit_test.dart) (FR-013). _(Same file as T011/T027/T030 — not `[P]`.)_
- [X] T036 [P] Privacy audit: confirm no code/payload/peer id in logs across scan + QR-display paths (`AppLogger` phase/error-type only — FR-024, Constitution I).
- [X] T037 [P] Reduce-Motion + a11y pass: steady brightness (no flash), Semantics on QR + scan controls + torch + Open Settings (FR-022/023).
- [X] T038 [P] Update [.claude/claude-app/ui-design-context.md](../../.claude/claude-app/ui-design-context.md) §Screen 03 (QR tab implemented) + §Screen 04 (Quét mã QR → scanner page) to reflect the shipped UI.
- [X] T039 Run the full gate: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all pass).
- [X] T040 On merge: append [.claude/claude-app/changelog.md](../../.claude/claude-app/changelog.md) entry + flip #007 status in [project-context.md](../../.claude/claude-app/project-context.md) / [sdd-roadmap.md](../../.claude/claude-app/sdd-roadmap.md) (mark #008 Next) + update [CLAUDE.md](../../CLAUDE.md) stack line.
- [ ] T041 **[DEFERRED — device-only]** Two-physical-device QR smoke per [quickstart.md](quickstart.md): present→scan→transfer, pick-from-photo, torch, brightness restore, permission recovery, foreign/expired QR; record `pod install` / `Podfile.lock` churn.

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (P1)**: no deps — start immediately.
- **Foundational (P2)**: depends on Setup — **blocks all stories** (codec, route, handoff fields, ARB).
- **US1 / US2 (both P1)**: depend on Foundational; otherwise independent and together = MVP.
- **US3 / US4 (P2)**: depend on Foundational + the `QrScanCubit`/`QrScanPage` created in US1 (they extend the scanner). US3 ⟂ US4.
- **Polish (P7)**: after the desired stories.

### Story independence

- **US2** is fully standalone (sender side only — needs no scanner).
- **US1** is testable with any external QR source; its e2e demo pairs with US2's output.
- **US3 & US4** build on US1's scanner page/cubit but are independently demoable (pick-from-photo; permission recovery).

### Within a story

- Tests written first and expected to fail → implementation. State/enum → cubit → page → wiring. Codegen (T016) after freezed/injectable files exist.

### Parallel opportunities

- Setup: T002 / T003 / T004 in parallel (after T001).
- Foundational: T005+T006 (codec+test) ∥ T010 (ARB); T007/T008 are small core edits.
- US1: T011 ∥ T012 (tests); T013 before T014 before T015.
- US2: can run in parallel with US1 by a second developer (different files, except both touch `connect_page.dart` for the method-set in T018/T025 — serialize those two).

---

## Parallel Example: MVP (US1 ∥ US2)

```bash
# After Foundational, two developers:
# Dev A — US1 (receiver scan):  T011,T012 (tests) → T013→T014→T015→T016→T017→T018→T019→T020
# Dev B — US2 (sender QR):      T021 (test) → T022→T023→T024→T025→T026
# Coordinate connect_page.dart edits (T017/T018 vs T024/T025) to avoid a merge clash.
```

---

## Implementation Strategy

### MVP first (US1 + US2 — both P1)

1. Phase 1 Setup → Phase 2 Foundational.
2. Build **US2** (gives a real QR artifact) then **US1** (scan it) — or in parallel.
3. **STOP & VALIDATE**: A shows QR → B scans → transfer → both records `qr`; tab-switch keeps the code.

### Incremental delivery

4. Add **US3** pick-from-photo → demo.
5. Add **US4** permission recovery → demo.
6. Polish (P7) → run quickstart → deferred two-device smoke (T041) → merge hygiene (T040).

---

## Notes

- `[P]` = different files, no incomplete-task deps.
- `connect_page.dart` is touched by both US1 (T017/T018) and US2 (T024/T025) — not `[P]` against each other.
- Reuse over new: single hosting session (no new `host()`), `joinWithCode` for join, `file_picker` for pick-from-photo, reserved `PairingMethod.qr` (no schema change).
- No engine/signaling/transport edits (Constitution VIII) — the only merged-code edits are the additive handoff fields + the two mappers + the Home action.
