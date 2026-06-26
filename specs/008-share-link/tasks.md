---
description: "Task list for #008 Share Link"
---

# Tasks: Share Link

**Input**: Design documents from `/specs/008-share-link/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md), [quickstart.md](quickstart.md)

**Tests**: INCLUDED — Constitution XII mandates unit tests for logic, `bloc_test` for all Cubits, and widget tests for transfer-critical flows.

**Organization**: Tasks are grouped by user story. **US1** (receiver taps a link → auto-join) and **US2** (sender shares the link) are both **P1** and together form the share-link MVP. **US3** (interrupt during a transfer) is P2 hardening.

---

## ⚠️ Deferred / device-only tasks (track here per Constitution XII)

- **T025** Two-physical-device cold + warm smoke — tap a real shared `safesend://` link from a chat app with the receiver app **closed** (cold) and **open** (warm); plus on-device self-invite + expired-link toasts. Cannot run in CI; see [quickstart.md](quickstart.md) §B–E.
- **First `pod install`** after T001 churns `ios/Podfile.lock` (the `app_links` pod) — commit the lock; folds into the next on-device build.
- **bloc-lint CLI** still uninstalled (tracked since #001) — gate step skipped, not failed.

> Quality gate per task group: `dart format .` · `dart analyze lib test` (0 issues — `flutter analyze` crashes on this checkout) · `flutter test`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add `app_links` and natively register the `safesend://` scheme (Constitution XV — version verified pub.dev 2026-06-26 in research.md; 7.x needs Dart ^3.12, so pinned to 6.4.1).

- [X] T001 Add `app_links: ^6.4.1` to [pubspec.yaml](../../pubspec.yaml) (NOT 7.x — Dart 3.11 floor), run `flutter pub get`, commit `pubspec.lock`.
- [X] T002 [P] iOS: add the `CFBundleURLTypes` entry for scheme `safesend` (per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C2) to [ios/Runner/Info.plist](../../ios/Runner/Info.plist).
- [X] T003 [P] Android: add the `safesend`/`connect` `VIEW` intent-filter (per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C3) to `.MainActivity` in [android/app/src/main/AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml); confirm the dev-flavor manifest still merges cleanly.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The core deep-link delivery seam, self-invite registry, additive handoff types, and ARB copy every story depends on. Reuses the #007 `ConnectLink` codec verbatim (no new codec task).

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create the `DeepLinkService` interface (`Future<Uri?> getInitialLink()` + `Stream<Uri> get links`) in [lib/core/services/deeplink/deep_link_service.dart](../../lib/core/services/deeplink/deep_link_service.dart) per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C4.
- [X] T005 Implement `DeepLinkServiceImpl` (`@LazySingleton`, wraps `AppLinks()` → `getInitialLink()` + `uriLinkStream`; imports no features; logs no URL contents) in [lib/core/services/deeplink/deep_link_service_impl.dart](../../lib/core/services/deeplink/deep_link_service_impl.dart).
- [X] T006 [P] Create `ActiveHostingRegistry` interface + `@LazySingleton` impl (nullable `activeHostingCode`, `setHosting`, `clear`; never logged) in [lib/core/services/pairing/active_hosting_registry.dart](../../lib/core/services/pairing/active_hosting_registry.dart) per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C5.
- [X] T007 [P] Add additive field `String? autoJoinCode` (receiver-only, default null) to `ConnectRequest` in [lib/core/domain/pairing/connect_handoff.dart](../../lib/core/domain/pairing/connect_handoff.dart).
- [X] T008 Create the core `ReceiveEntryRequest` type (`{bool openScanner = false, String? autoJoinCode}`) in [lib/core/domain/pairing/receive_entry_request.dart](../../lib/core/domain/pairing/receive_entry_request.dart); widen the `AppRoutes.receive` builder extra from `bool?` to `ReceiveEntryRequest?` in [lib/core/router/app_router.dart](../../lib/core/router/app_router.dart); update the two Home call sites (Nhận → `ReceiveEntryRequest()`, Quét QR → `ReceiveEntryRequest(openScanner: true)`) in [lib/features/home/presentation/home_page.dart](../../lib/features/home/presentation/home_page.dart).
- [X] T009 [P] Add #008 ARB strings (VI primary + EN, each with `@description`, keep key parity) to [lib/l10n/arb/app_vi.arb](../../lib/l10n/arb/app_vi.arb) + [lib/l10n/arb/app_en.arb](../../lib/l10n/arb/app_en.arb): `connectShareLinkMessage`, `shareLinkInvalid`, `shareLinkExpired`, `shareLinkOwn`, `shareLinkLeaveTransferTitle`, `shareLinkLeaveTransferBody`, `shareLinkLeaveTransferConfirm`, `shareLinkLeaveTransferCancel` (per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C8).
- [X] T010 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate the injectable DI graph (new `@LazySingleton`s) + l10n, then `dart analyze lib test` = 0.

**Checkpoint**: Delivery service + registry + handoff types + copy ready — stories can proceed.

---

## Phase 3: User Story 1 — Receiver taps a link and lands in Receive (Priority: P1) 🎯 MVP

**Goal**: Tapping a valid invite link (warm or cold) routes the receiver straight into the Receive flow with the room auto-joined, into the accept/reject prompt — no digits, no scan.

**Independent Test**: With any device hosting a live code, construct its `safesend://connect?v=1&code=…` link and open it on the receiver (app open, then app closed) → reaches the incoming-transfer prompt; History tags the record "Chia sẻ link".

### Tests for User Story 1 ⚠️

- [X] T011 [P] [US1] Unit-test the deep-link coordinator decision table (valid→go(receive) with `ReceiveEntryRequest.autoJoinCode`; malformed→`shareLinkInvalid` toast + go(home); own-code→`shareLinkOwn` toast, no nav; latest-wins serialization) with a fake `DeepLinkService` + fake `ActiveHostingRegistry` + test router in [test/core/router/deep_link_coordinator_test.dart](../../test/core/router/deep_link_coordinator_test.dart). **Also assert log hygiene (Constitution I, FR-021): handling a link emits no log line containing the 6-digit code or the raw URL** (capture `AppLogger` output over the valid + malformed cases).
- [X] T012 [P] [US1] Widget test: the receiver Connect panel given `ConnectRequest(role: receiver, autoJoinCode: '123456')` auto-calls `joinWithCode` and yields `ConnectResult(method: shareLink)` reaching the accept/reject prompt, in [test/features/pairing/connect_auto_join_test.dart](../../test/features/pairing/connect_auto_join_test.dart).

### Implementation for User Story 1

- [X] T013 [US1] Create the core-pure `DeepLinkCoordinator` (parse via `ConnectLink.parse`; on failure → `AppToast` `shareLinkInvalid` + `context.go(AppRoutes.home)`; on success → self-invite check vs `ActiveHostingRegistry` (`shareLinkOwn` toast, stop) then `context.go(AppRoutes.receive, extra: ReceiveEntryRequest(autoJoinCode: code))`; serialize latest-wins) in [lib/core/router/deep_link_coordinator.dart](../../lib/core/router/deep_link_coordinator.dart) per [contracts/deep-link-contracts.md](contracts/deep-link-contracts.md) §C6.
- [X] T014 [US1] Thread auto-join through Receive: pass `ReceiveEntryRequest.autoJoinCode` from [lib/features/receive/presentation/pages/receive_entry_page.dart](../../lib/features/receive/presentation/pages/receive_entry_page.dart) into the receiver `ConnectRequest.autoJoinCode`; in [lib/features/pairing/presentation/connect/connect_page.dart](../../lib/features/pairing/presentation/connect/connect_page.dart) the receiver panel, when `autoJoinCode != null`, calls `joinWithCode(code)` once on init and sets the paired method to `PairingMethod.shareLink`.
- [X] T015 [US1] Wire delivery + cold/warm: instantiate `DeepLinkService` early in [lib/bootstrap.dart](../../lib/bootstrap.dart); mount the coordinator under the router (subscribe `links` for warm; process `getInitialLink()` once in a post-first-frame callback for cold — FR-011) in [lib/app/app.dart](../../lib/app/app.dart).
- [X] T016 [US1] Map a syntactically-valid-but-expired/consumed code: the auto-join failure (`roomExpired`/`invalidCode`) surfaces `shareLinkExpired` toast + `context.go(AppRoutes.home)` (same destination warm + cold) in the receiver auto-join handler (connect_page.dart / receive_entry_page.dart).

**Checkpoint**: US1 fully functional — receiver pairs by tapping a link (warm + cold), invalid/expired/own links land safely. **MVP demoable.**

---

## Phase 4: User Story 2 — Sender shares an invite link (Priority: P1)

**Goal**: The Connect hub's "Chia sẻ link mời" action opens the system share sheet carrying the live session's invite link; sharing never regenerates the code or opens a second connection.

**Independent Test**: Send → Connect hub → tap "Chia sẻ link mời" → share sheet carries `…&code=<live code>`; switching Mã 6 số ↔ QR ↔ link never changes the code.

### Tests for User Story 2 ⚠️

- [X] T017 [P] [US2] Widget test: tapping "Chia sẻ link mời" builds `ConnectLink.build(<live code>)` from the **current** `PairingState.hosting` code (assert the link tracks the live code, FR-004) and invokes the share service with the invite text + link (mock the share seam); switching tabs/actions does not regenerate the code (FR-003); and after sharing, the session pairs with `ConnectResult.method == PairingMethod.shareLink` (FR-017 sender side), in [test/features/pairing/connect_share_link_test.dart](../../test/features/pairing/connect_share_link_test.dart).

### Implementation for User Story 2

- [X] T018 [US2] Implement the stubbed `_HostingPanel` "Chia sẻ link mời" `SecondaryButton` (currently `onPressed: null`) in [lib/features/pairing/presentation/connect/connect_page.dart](../../lib/features/pairing/presentation/connect/connect_page.dart): read the active code from the sender `PairingState.hosting`, build `ConnectLink.build(code)`, and call `SharePlus.instance.share(ShareParams(text: '${l10n.connectShareLinkMessage}\n<link>'))` (reuse the share_plus 12.0.2 API). **Set the sender's pending paired-method to `PairingMethod.shareLink`** (last-action-wins — reuse the #007 `_pairedViaQr`-style flag so a later QR-tab switch overrides it) so `ConnectResult.method = shareLink` when the peer pairs via this session (FR-017 sender side).
- [X] T019 [US2] In [lib/features/pairing/data/pairing_repository_impl.dart](../../lib/features/pairing/data/pairing_repository_impl.dart), call `ActiveHostingRegistry.setHosting(code)` when a hosting code is emitted / rotates and `clear()` on dispose (enables FR-015 self-invite detection on device).

**Checkpoint**: US1 + US2 both work — a real end-to-end share→tap→pair loop is possible.

---

## Phase 5: User Story 3 — Interrupt during an active transfer (Priority: P2)

**Goal**: Opening an invite while a transfer is in progress prompts for confirmation before leaving; an active transfer is never silently dropped.

**Independent Test**: While on the progress screen, open an invite link → a confirm dialog appears; cancel keeps the transfer, confirm leaves and joins. From a non-transfer screen, no prompt.

### Tests for User Story 3 ⚠️

- [X] T020 [P] [US3] Widget test: with the router on `sendProgress`/`receiveProgress`, the coordinator shows the `shareLinkLeaveTransfer` confirm dialog (cancel → no nav; confirm → go(receive)); on a non-transfer route it routes with no dialog, in [test/core/router/deep_link_interrupt_test.dart](../../test/core/router/deep_link_interrupt_test.dart).

### Implementation for User Story 3

- [X] T021 [US3] Extend `DeepLinkCoordinator` (T013) to inspect the current router location: if it is `AppRoutes.sendProgress` or `AppRoutes.receiveProgress`, show the `shareLinkLeaveTransfer` confirm dialog before routing (cancel → discard the invite; confirm → proceed); otherwise route directly, in [lib/core/router/deep_link_coordinator.dart](../../lib/core/router/deep_link_coordinator.dart) (FR-014).

**Checkpoint**: All stories functional — interrupts are acknowledged, never silent.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T022 [P] Verify History renders `PairingMethod.shareLink` via the existing `PairingMethodL10n.label` (`historyMethodShareLink`); add a record-mapping test asserting a share-link-paired transfer persists `pairingMethod: shareLink` in [test/features/receive/receive_history_mapper_test.dart](../../test/features/receive/receive_history_mapper_test.dart) (extend, don't duplicate).
- [ ] T023 (deferred — manual simulator/emulator run) Run the [quickstart.md](quickstart.md) §A + §E plumbing checks locally (share sheet carries the link; malformed link → toast + Home) on a simulator/emulator.
- [X] T024 Final gate: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all prior + #008 new pass); confirm `pubspec.lock` committed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — start immediately. T002/T003 are [P] (different files).
- **Foundational (Phase 2)**: depends on Setup. T010 (codegen) depends on T004–T008. BLOCKS all stories.
- **US1 (Phase 3)**: depends on Foundational. The MVP slice.
- **US2 (Phase 4)**: depends on Foundational; independent of US1 (uses `ActiveHostingRegistry` from T006, share from existing share_plus). T019 makes US1's self-invite check real on device but US1 is testable without it (fake registry).
- **US3 (Phase 5)**: depends on Foundational + the coordinator from US1 (T013); extends it.
- **Polish (Phase 6)**: after the desired stories.

### Within Each User Story

- Tests (T011/T012, T017, T020) written first and FAIL before implementation.
- Core seams (Phase 2) before coordinator/UI wiring.
- Coordinator (T013) before its interrupt extension (T021).

### Parallel Opportunities

- T002 ‖ T003 (native iOS/Android).
- T004 ‖ T006 ‖ T007 ‖ T009 (different files); T005 after T004; T008 after T007.
- T011 ‖ T012 (US1 tests); T017 (US2) can run alongside US1 work.
- US1 and US2 can be built by different developers once Phase 2 is done.

---

## Parallel Example: Foundational

```bash
# Different files, no inter-dependencies:
Task: "T004 DeepLinkService interface in lib/core/services/deeplink/deep_link_service.dart"
Task: "T006 ActiveHostingRegistry in lib/core/services/pairing/active_hosting_registry.dart"
Task: "T007 ConnectRequest.autoJoinCode in lib/core/domain/pairing/connect_handoff.dart"
Task: "T009 ARB strings in lib/l10n/arb/app_vi.arb + app_en.arb"
```

---

## Implementation Strategy

### MVP First (US1 + US2 — both P1)

1. Phase 1 Setup → Phase 2 Foundational → US1 (receiver tap) → US2 (sender share).
2. **STOP and VALIDATE**: a sender shares a link, a receiver taps it (warm + cold) and pairs. This is the demoable MVP.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. US1 → receiver tap-to-pair (paired against any link source) → demo.
3. US2 → sender share action → full share→tap loop → demo.
4. US3 → interrupt safety → demo.
5. Polish + deferred two-device smoke (T025).

---

## Notes

- [P] = different files, no incomplete-task dependencies. [Story] maps each task to a user story.
- The coordinator (`lib/core/router/deep_link_coordinator.dart`) stays **core-pure** — it navigates by `AppRoutes` + core-typed `ReceiveEntryRequest`, importing no feature pages (Constitution XI).
- No engine/signaling/transport/protocol/DB-schema changes; `PairingMethod.shareLink` reuses the #006 enum/mappers.
- Commit after each task or logical group; verify tests fail before implementing.
