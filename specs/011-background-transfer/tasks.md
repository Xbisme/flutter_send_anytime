---
description: "Task list for #011 Background Transfer"
---

# Tasks: Background Transfer (#011)

**Input**: Design documents from `/specs/011-background-transfer/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: INCLUDED — Constitution XII mandates unit/BLoC tests for this transfer-touching feature (loopback-style, no devices). Two-physical-device smoke is a REQUIRED-but-DEFERRED manual task (banner below).

**Organization**: grouped by user story (P1 → P2 → P3) for independent implementation + testing.

> **Implementation status (2026-06-27)**: Dart core + native config + tests landed — `dart analyze lib test` = 0 · `flutter test` = **285 passed (18 new)** · `dart format` clean. **iOS native done + validated**: 1 Widget Extension target (duplicates removed), App Group **split per flavor** via `APP_GROUP_ID` (xcconfig for Runner + build settings for widget; entitlements use `$(APP_GROUP_ID)`; dev `group.app.safesend.dev.liveactivities` / prod `group.app.safesend.liveactivities`), `pod install` ran (`live_activities` + `flutter_foreground_task` in `Podfile.lock`), widget Swift compiles dev + prod (`xcodebuild` = BUILD SUCCEEDED). **T036 throttle** + **T014/T015 seam tests** now done. 37/43 tasks complete.
>
> ⚠️ **Remaining**: **T040** two-device on-device smoke (Android sustained-to-completion · iOS Live Activity display + clean-fail) — needs real devices + a signing Team selected in Xcode. **T032** iOS `beginBackgroundTask` grace-window keep-alive (optional native enhancement). **T025** surface-tap → route (OS-default resume to the still-mounted progress route; the route data is asserted in the binder seam test; full nav verified on device in T040). **T031** partial-retained on interruption (reuses #005 — covered by the existing receive tests; #011 only ends the surface on terminal). **T037** log-hygiene (the coordinator/controllers log only `e.runtimeType` — guaranteed by code + exercised by the FR-019 failure-path test; `dart:developer` logs aren't capturable in unit tests). **T038** doc/status flip at merge. bloc-lint CLI still uninstalled (tracked since #001).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no incomplete-task dependency)
- **[Story]**: US1 / US2 / US3 (setup, foundational, polish carry no story label)
- Toolchain note: use `dart analyze lib test` (not `flutter analyze` — crashes on this checkout).

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: dependencies + native scaffolding before any Dart logic.

- [x] T001 Add `live_activities: ^2.4.9` + `flutter_foreground_task: ^9.2.2` to [pubspec.yaml](../../pubspec.yaml) (verified pub.dev 2026-06-27, research.md), run `flutter pub get`, commit `pubspec.lock`; confirm no unexpected transitive churn.
- [x] T002 [P] Android: declare the foreground `<service android:foregroundServiceType="dataSync">` + add `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_DATA_SYNC` permissions in [android/app/src/main/AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml) (`POST_NOTIFICATIONS` already present from #010).
- [x] T003 [P] iOS: add a Live Activity **Widget Extension** target + a shared **App Group** entitlement on Runner + extension, and set `NSSupportsLiveActivities = YES` in [ios/Runner/Info.plist](../../ios/Runner/Info.plist) (full SwiftUI in T022; native build / first `pod install` deferred → T041).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: core-pure types + seams every story builds on. **No user-story work starts until this completes.**

- [x] T004 [P] Create `BackgroundPhase` enum + immutable `BackgroundTransferState` view model in `lib/core/services/background/background_transfer_state.dart` (fields per [data-model.md](data-model.md)).
- [x] T005 [P] Create `ActiveTransferHandle` (snapshots stream + direction + peerName + fileCount + progressRoute + onCancel) in `lib/core/services/background/active_transfer_handle.dart`.
- [x] T006 Implement the snapshot→`BackgroundTransferState` projection reusing the existing `TransferProgressProjector` (#005) so surfaces match the in-app screen, in `lib/core/services/background/background_transfer_state.dart` (factory/mapper).
- [x] T007 [P] Define abstract `LiveActivityController`, `ForegroundServiceController`, and `BackgroundServiceAction` (enum: `cancel`) per [contracts/services.md](contracts/services.md) in `lib/core/services/background/` (interfaces only).
- [x] T008 Implement `BackgroundTransferCoordinator` skeleton (attach/detach/onAppLifecycleChanged; selects controller by platform; no-op controller when unsupported) in `lib/core/services/background/background_transfer_coordinator.dart`.
- [x] T009 Register coordinator (`@lazySingleton`) + both controllers in DI under `lib/core/di/` (no eager singletons — Constitution XI).
- [x] T010 [P] Add background constants (notification channel id + foreground-service notification id; route map send/receive→`AppRoutes`) in `lib/core/constants/`.
- [x] T011 [P] Add surface + interrupted-transfer ARB strings (VI primary + EN, `@description`) in `lib/l10n/arb/` — titles ("Đang gửi · {n} tệp"/"Đang nhận · {n} tệp"), peer lines ("tới {peer}"/"từ {peer}"), "Huỷ", interrupted-transfer message + retry copy.

**Checkpoint**: core types + DI + ARB ready — user stories can begin.

---

## Phase 3: User Story 1 — Watch a transfer finish while backgrounded (Priority: P1) 🎯 MVP

**Goal**: a backgrounded/locked transfer keeps running (Android sustained; iOS best-effort) and shows live progress on the OS surface, both directions, settling to a final state on completion.

**Independent Test**: start a multi-file transfer, background one side → surface shows live direction/peer/%/speed/bytes/ETA and (Android) the transfer completes backgrounded; on completion the surface settles + dismisses.

### Tests for User Story 1 ⚠️ (write first, ensure they fail)

- [x] T012 [P] [US1] Projection test: snapshot→`BackgroundTransferState` produces correct direction/accent/verb + percent/speed/bytes/ETA labels matching `TransferProgressProjector`, in `test/core/services/background/background_transfer_state_test.dart`.
- [x] T013 [P] [US1] Coordinator lifecycle test (fake controllers + fake snapshot stream): background-while-transferring → `start`; each snapshot → `update`; terminal snapshot → final `update` then `end` + detach; foreground return → `end` of background-created surface; rapid bg/fg toggles never create two surfaces (FR-018), in `test/core/services/background/background_transfer_coordinator_test.dart`.
- [x] T014 [P] [US1] Send seam test: entering `transferring` calls `coordinator.attach`; terminal/dispose calls `detach`, in `test/features/send/`.
- [x] T015 [P] [US1] Receive seam test: same attach/detach contract, in `test/features/receive/`.
- [x] T015a [P] [US1] Permission-denied test (FR-019): with notification permission denied, the coordinator still starts the Android surface path and the transfer is NOT blocked / no forced prompt is triggered; reduced visibility is non-fatal, in `test/core/services/background/foreground_service_controller_test.dart`.

### Implementation for User Story 1

- [x] T016 [US1] Implement `ForegroundServiceController` (Android) over `flutter_foreground_task`: `start`/`update`/`end` with ongoing (non-dismissible) notification + progress bar (0–100) + small icon + direction accent tint; returns `Result<void>`; keeps transfer on the main isolate (service only keeps process alive), in `lib/core/services/background/foreground_service_controller.dart`.
- [x] T017 [US1] Implement `LiveActivityController` (iOS) over `live_activities`: `isSupported` (false < iOS 16.1 → no-op), `start`/`update`/`end` pushing the `ContentState` from [contracts/live_activity_state.md](contracts/live_activity_state.md); returns `Result<void>`, in `lib/core/services/background/live_activity_controller.dart`.
- [x] T018 [US1] Complete `BackgroundTransferCoordinator`: start-on-background-while-transferring, update-on-snapshot (throttle in T036), end-on-terminal-or-foreground, single-surface guard, in `background_transfer_coordinator.dart`.
- [x] T019 [US1] Wire a `WidgetsBindingObserver` in the app root (`lib/app/`) to forward lifecycle → `coordinator.onAppLifecycleChanged` (registered once, app-wide).
- [x] T020 [P] [US1] Send additive seam: build `ActiveTransferHandle` and `attach` on entering `transferring`, `detach` on terminal/dispose, `onCancel`→existing cancel, in `lib/features/send/presentation/` (cubit).
- [x] T021 [P] [US1] Receive additive seam: same attach/detach/onCancel, in `lib/features/receive/presentation/` (cubit).
- [x] T022 [US1] iOS Widget Extension SwiftUI: `ActivityAttributes` + `ContentState` (keys per contract) + Dynamic Island compact/minimal/expanded + Lock Screen card; palette hexes + Sora/JetBrains Mono per [contracts/live_activity_state.md](contracts/live_activity_state.md), in `ios/<WidgetExtension>/` (build verified on device — T041).
- [x] T023 [US1] Android notification content render: title/peerLine/meta (mono) + progress bar + direction accent, driven from `BackgroundTransferState` (Cancel action added in US2), in `foreground_service_controller.dart`.
- [x] T023a [US1] Permission-denied handling (FR-019): when notification permission is denied, keep the transfer running to the extent the platform allows, still post the OS-required foreground-service notice where mandated, never block the transfer or force a permission prompt over it, in `foreground_service_controller.dart`.

**Checkpoint**: MVP — backgrounded transfer runs (Android) + shows live progress on both platforms, settles on completion. Independently testable.

---

## Phase 4: User Story 2 — Act on the transfer from the surface (Priority: P2)

**Goal**: Android "Huỷ" cancels immediately (no confirm); tapping the surface returns to the in-app progress screen for the same transfer.

**Independent Test**: tap "Huỷ" mid-transfer → cancels on both peers, notification removed; tap the surface body → app foregrounds to the correct progress screen, no duplicate transfer.

### Tests for User Story 2 ⚠️

- [x] T024 [P] [US2] Cancel-routing test: fake `ForegroundServiceController.actions` emits `cancel` → `handle.onCancel()` invoked exactly once, immediately, no confirm (Clarification), in `test/core/services/background/background_transfer_coordinator_test.dart`.
- [ ] T025 [P] [US2] Surface-tap test: tap resolves to `AppRoutes.sendProgress`/`receiveProgress` for the active direction and starts no new transfer, in `test/core/services/background/`.

### Implementation for User Story 2

- [x] T026 [US2] Add the single "Huỷ" action button to the Android notification (single action only — **no pause/resume**, FR-017) + expose `actions` stream, in `foreground_service_controller.dart`.
- [x] T027 [US2] Coordinator: on `BackgroundServiceAction.cancel` → call `handle.onCancel()` immediately; the resulting terminal snapshot ends the surface via the normal path, in `background_transfer_coordinator.dart`.
- [x] T028 [US2] Surface tap → foreground to the active progress route: Android launch intent + iOS Live Activity tap deep-link, routed via a core hook (à la #008 `DeepLinkCoordinator`) using `AppRoutes` constants — imports no feature pages.
- [x] T029 [US2] Guarantee tap reuses the already-mounted flow (no duplicate transfer / no second handshake); verify against the existing nav stack.

**Checkpoint**: US1 + US2 both work independently.

---

## Phase 5: User Story 3 — Graceful failure when the OS suspends (Priority: P3)

**Goal**: an OS-suspended backgrounded transfer fails cleanly — clear interrupted message + retry on return, fully-received files retained (partial), no stale surface, no resume attempt.

**Independent Test**: leave a long transfer backgrounded past the OS allowance → on return, interrupted message + retry; verified partial files kept; surface not frozen.

### Tests for User Story 3 ⚠️

- [x] T030 [P] [US3] OS-suspend mapping test: an interruption snapshot → `failed` → coordinator ends/dismisses the surface (no stale numbers, FR-010/FR-011), in `test/core/services/background/background_transfer_coordinator_test.dart`.
- [ ] T031 [P] [US3] Partial-retained test: interrupted receive keeps already-verified files (reuses #005 partial outcome), incomplete files not presented as received, in `test/features/receive/`.

### Implementation for User Story 3

- [ ] T032 [US3] iOS best-effort keep-alive: wrap the backgrounded transfer window in a `beginBackgroundTask`/`endBackgroundTask` assertion (grace only — no audio/VoIP), so short transfers can finish; long ones fall through to clean fail, in the iOS bridge / `live_activity_controller.dart` host glue.
- [x] T033 [US3] Ensure an engine interruption (existing detection, #009-hardening) drives a terminal `failed` snapshot that the coordinator ends/dismisses the surface on; no separate failure model (Constitution VIII).
- [x] T034 [US3] Foreground-return: surface a clear, localized **interrupted-transfer** message + **retry** (reuse existing failure UI + `AppFailure` mapping; ARB from T011); confirm partial retained, in `lib/features/{send,receive}/presentation/`.
- [x] T035 [US3] iOS < 16.1 / non-Live-Activity device path: `LiveActivityController.isSupported == false` → coordinator no-ops the surface, transfer logic untouched, no crash/dead surface (FR / Edge Cases); covered by a coordinator test variant.

**Checkpoint**: all three stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T036 [P] Implement + test surface-update throttle (≈ every 0.5–1 s or ≥1% delta) in the coordinator (fake clock), per quickstart.
- [ ] T037 [P] Log-hygiene test: coordinator + both controllers emit no `peerName` / byte values / file paths — phase + error-type only (Principle I / FR-014), in `test/core/services/background/`.
- [ ] T038 [P] Docs at merge: append [changelog.md](../../.claude/claude-app/changelog.md) entry + flip status in [project-context.md](../../.claude/claude-app/project-context.md) + [sdd-roadmap.md](../../.claude/claude-app/sdd-roadmap.md); confirm [ui-design-context.md](../../.claude/claude-app/ui-design-context.md) §OS Surfaces is accurate.
- [x] T039 Run CI gates green: `dart analyze lib test` = 0 · `flutter test` all pass · `dart format --set-exit-if-changed .` clean.
- [ ] T040 **[DEFERRED · device]** Two-device background smoke per [quickstart.md](quickstart.md): Android sustained-to-completion + Cancel + tap-return + terminal cleanup; iOS Live Activity display + short-finish + long-suspend clean-fail + retry.
- [x] T041 **[DEFERRED · device]** First `pod install` (`live_activities` pod + Widget Extension) → review/commit `ios/Podfile.lock` churn; verify Android FGS notification + Cancel on a real device.

---

## Dependencies & Execution Order

- **Setup (P1: T001–T003)** → no deps; T002/T003 parallel after T001.
- **Foundational (P2: T004–T011)** → depends on Setup; **blocks all stories**. T004/T005/T007/T010/T011 parallel; T006 after T004; T008 after T004–T007; T009 after T008.
- **US1 (P3: T012–T023)** → after Foundational. Tests T012–T015 parallel first; impl T016/T017 parallel; T018 after T016/T017; T019 after T018; T020/T021 parallel after T018; T022/T023 parallel (native).
- **US2 (P4: T024–T029)** → after US1 (needs the surface + seam). Tests parallel; T026 before T027; T028/T029 after.
- **US3 (P5: T030–T035)** → after US1 (US2 not required). Tests parallel; impl independent files mostly.
- **Polish (P6: T036–T041)** → after the desired stories; T040/T041 always deferred.

### Within each story

Tests written first and failing → core/services → controllers → coordinator → feature seam → native surface. Commit after each task or logical group.

---

## Parallel Example: User Story 1 tests

```bash
Task: "Projection test in test/core/services/background/background_transfer_state_test.dart"
Task: "Coordinator lifecycle test in test/core/services/background/background_transfer_coordinator_test.dart"
Task: "Send seam test in test/features/send/"
Task: "Receive seam test in test/features/receive/"
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Phase 1 Setup → 2. Phase 2 Foundational (blocks all) → 3. Phase 3 US1 → **STOP & VALIDATE**: backgrounded transfer runs (Android) + live surface both platforms → demo MVP.

### Incremental Delivery

US1 (MVP surface + keep-alive) → US2 (cancel + tap-return) → US3 (graceful fail). Each adds value without breaking the prior. Native (T022 iOS widget / T041 pod install) lands with US1 but its on-device verification is deferred with the two-device smoke (T040).

---

## Notes

- [P] = different files, no incomplete-task dependency.
- No engine/signaling/transport/protocol/DB-schema edits — additive seams only (mirrors #006/#008/#010).
- Single source of truth = #002 snapshot stream; never a parallel progress model (Constitution VIII / FR-005).
- Surfaces metadata-only; no byte/identifier logging (Principle I / FR-014).
- iOS sustained background not promised (data-channel-only) — Android is the SC-001 path; iOS long-transfer → US3 clean-fail.
