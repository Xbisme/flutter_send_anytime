---
description: "Task list for #005 Receive Flow (Nhận)"
---

# Tasks: Receive Flow (Nhận)

**Input**: Design documents from `specs/005-receive-flow/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Status**: ✅ **IMPLEMENTED + DEVICE-VALIDATED** 2026-06-25 — **34/34 tasks done**. `dart analyze lib test` = 0 · `flutter test` = 128 passed · `dart format` clean. ⭐ **MVP loop validated on two physical iPhones** (pair → send → receive → save, repeated back-to-back). T034 done. A device-hardening pass fixed: early-ICE buffering, signaling reconnect, flutter_webrtc teardown race, zero-byte/same-dir finalize, and the end-of-transfer channel-close race.

**Tests**: INCLUDED — Constitution XII mandates `bloc_test` for all Cubits, widget tests for transfer-critical flows (Receive accept/reject + progress), and a loopback round-trip for transfer-protocol changes; the plan enumerates the required coverage.

> ⚠️ **Deferred (device-only)**: the **two-physical-device receive smoke** (real NAT + multi-GB throughput + the full pair→send→receive→save MVP dogfood) cannot run in CI — tracked as **T034**, expected to remain deferred until the first on-device build. `share_plus` 13.x Android toolchain (Java 17 / AGP ≥ 8.12.1) + iOS Files Info.plist keys fold into that device build.

**Org**: tasks grouped by user story. Build order among the three P1 stories: **US3 (receiver code entry) → US2 (accept/reject decision) → US1 (full receive integration = MVP)**, then P2 story US4 (save/open/share). Each story is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete-task dependency)
- **[Story]**: US1–US4 (user-story phases only)

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Add `path_provider: ^2.1.6`, `share_plus: ^12.0.2` (pinned: 13.x win32 conflicts with file_picker 11), `open_filex: ^4.7.0` to `dependencies` in `pubspec.yaml` (verified pub.dev 2026-06-25, Constitution XV); run `flutter pub get`; confirm `pubspec.lock` updated; note `share_plus` 13.x Android toolchain (Java 17 / AGP ≥ 8.12.1) as a deferred-device-build item, no pod churn on the document path
- [x] T002 [P] Add `receiveProgress = '/receive/progress'` constant to `lib/core/constants/app_routes.dart` (reuses existing `connect`)
- [x] T003 [P] Confirm the shared widgets the receive flow reuses exist in `lib/core/presentation/` (FileRow/FileChip, Primary/Secondary/DangerButton, AppToast, FlowAppBar, TransferSpinner, gradient ProgressBar); list any missing for Phase 2

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: Must complete before any user story phase. Covers the engine seam, the shared-UI lift, core services/models, and ARB.

- [x] T004 [P] Engine seam: refactor `TransferEngine.startReceive` into `_establish` + a shared `_runReceive(transport, destinationDir, onManifest)` body, and add `startReceiveOnTransport({required DataTransport transport, required Directory destinationDir, Future<bool> Function(TransferManifest) onManifest = _autoAccept})` (adopts the open transport via `_adoptTransport`, runs `_runReceive` from handshaking) in `lib/core/services/transport/transfer_engine.dart` — per [contracts/transfer-engine-seam.md](contracts/transfer-engine-seam.md)
- [x] T005 [P] Create `ReceivedFilesService` interface + `ReceivedFilesServiceImpl` (`destinationDirectory()` → `path_provider.getApplicationDocumentsDirectory()`+`/SafeSend` created if absent; `share(paths)` → `SharePlus.instance.share(ShareParams(files:[XFile…]))`; `open(path)` → `OpenFilex.open` mapping non-success → `Result` failure; never logs paths) in `lib/core/services/file/received_files_service.dart` + `received_files_service_impl.dart`; register `@LazySingleton(as: ReceivedFilesService)`
- [x] T006 Shared-UI lift (model): move/rename `features/send`'s `SendTransferView` → `lib/core/domain/transfer/transfer_view.dart` as role-neutral `TransferView` (rename `bytesSent`→`bytesDone`; add `role`, `awaitingDecision`, `incomingOffer`, `isPartial`/`completedCount`; carry `fromSnapshot` logic); update all `features/send` references — per [data-model.md](data-model.md) §1
- [x] T007 Shared-UI lift (widgets): move the progress + complete UI from `features/send/presentation/pages/send_transfer_page.dart` into `lib/core/presentation/transfer/{transfer_progress_view.dart,transfer_complete_view.dart}` parameterized by `TransferRole` (badge "ĐANG GỬI"/"ĐANG NHẬN"; terminal actions sender=Gửi lại/Xong, receiver=per-file Mở + Chia sẻ/Xong; `isPartial` summary), plus a shared `transfer_progress_projector.dart` (speed/ETA smoothing) — and **update `SendTransferCubit` (`lib/features/send/presentation/cubit/send_transfer_cubit.dart`) to consume the shared projector** instead of its inline smoothing so the logic lives in one place; rewire `send_transfer_page.dart` (sender role) to the shared widgets so #004 behavior + tests are unchanged (depends on T006)
- [x] T008 [P] Create `IncomingOffer` freezed model (`senderLabel`, `fileCount`, `totalBytes`, `typeSummary`) + `fromManifest(TransferManifest, senderLabel)` in `lib/core/domain/transfer/incoming_offer.dart`
- [x] T009 [P] Add ARB strings (VI primary + EN) for receive/prompt/connect copy (`receiveEnterCode`, `receiveConnecting`, `receivePromptTitle`, `receivePromptBody`, `receiveAccept`, `receiveReject`, `receiveProgressBadge`, `receiveCompleteTitle`, `receivePartialTitle`, `receiveOpen`, `receiveShare`, `receiveCancelConfirmTitle/Body/Confirm`, `receiveDone`, generic `senderLabel`) + receive-failure messages, with `@description`, in `lib/l10n/arb/app_vi.arb` + `app_en.arb`; add `receive_failure_l10n.dart` (AppFailure→message mapper) in `lib/features/receive/presentation/` — per [data-model.md](data-model.md) §6
- [x] T010 Run `dart run build_runner build --delete-conflicting-outputs` (freezed + injectable + l10n) and confirm `dart analyze lib test` is clean for the new foundation files + the migrated `features/send`

**Checkpoint**: engine seam + shared UI + services + models + ARB ready — story implementation can begin.

---

## Phase 3: User Story 3 - Pair via a 6-digit code (receiver side) (Priority: P1)

**Goal**: User opens Nhận, enters a 6-digit code into a focused field, sees connecting feedback, advances on connect, and gets clear distinct errors (invalid/expired/full/unreachable) that preserve the entered code.

**Independent Test**: render the Connect hub in receiver role; entering 6 digits enables Connect → calls `joinWithCode`; simulate each failure → distinct message, code retained, retry works.

### Tests for User Story 3

- [x] T011 [P] [US3] Widget test for `CodeInput` (digit-only, exactly 6, leading zeros, `onCompleted` fires at 6, Connect disabled until complete) in `test/features/pairing/code_input_test.dart`
- [x] T012 [P] [US3] Widget test for the Connect **receiver branch** (enter code → `PairingCubit.joinWithCode`; `invalidCode`/`roomExpired`/`roomFull`/`signalingUnreachable` → distinct message + code preserved + retry) in `test/features/pairing/connect_receiver_test.dart`

### Implementation for User Story 3

- [x] T013 [P] [US3] Create `CodeInput` widget (6-digit mono entry, digit-only input formatters, `onChanged`/`onCompleted`, a11y label, reduce-motion safe) in `lib/features/pairing/presentation/connect/widgets/code_input.dart`
- [x] T014 [US3] Add the receiver branch to `_CodeTab` in `lib/features/pairing/presentation/connect/connect_page.dart`: when `request.role == TransferRole.receiver`, render `CodeInput` + a Connect `PrimaryButton` → `joinWithCode(code)`; reuse the existing connecting/connected/failure panels; ensure failure keeps the code (FR-023) — per [contracts/receive-flow-contract.md](contracts/receive-flow-contract.md) §4

**Checkpoint**: receiver can enter a code and reach `connected` (returns `ConnectResult{transport}`) or a clear, retryable failure — testable without the rest of the flow.

---

## Phase 4: User Story 2 - Decide on an incoming transfer (Accept / Reject) (Priority: P1)

**Goal**: Before any bytes are written, the receiver sees the sender label + manifest (count/size/types) and explicitly accepts or rejects; reject writes nothing and ends both sides cleanly.

**Independent Test**: drive `ReceiveTransferCubit` against a loopback transport from a sender that sends a manifest; assert it emits `awaitingDecision` + `IncomingOffer`; `accept()` proceeds, `reject()` writes nothing and terminates; the dialog renders the offer and calls the right callback.

### Tests for User Story 2

- [x] T015 [P] [US2] `bloc_test` for `ReceiveTransferCubit` decision bridge (onManifest → loaded `awaitingDecision:true` + correct `IncomingOffer`; `accept()` completes true → transferring; `reject()` completes false → reject frame + `_rejectedByUser` set; no write before accept) in `test/features/receive/receive_transfer_cubit_decision_test.dart`
- [x] T016 [P] [US2] Widget test for `IncomingTransferDialog` (renders senderLabel/count/total/types per the Dialogs spec; **Nhận**→`accept`, **Từ chối**→`reject`) in `test/features/receive/incoming_transfer_dialog_test.dart`

### Implementation for User Story 2

- [x] T017 [P] [US2] Create `StartReceiveUseCase` (resolves `destinationDirectory()` then `engine.startReceiveOnTransport`; exposes `snapshots`, `cancel`, `dispose`) in `lib/features/receive/domain/usecases/start_receive_usecase.dart` — per [contracts/receive-flow-contract.md](contracts/receive-flow-contract.md) §2
- [x] T018 [US2] Create `ReceiveTransferCubit : AppCubit<TransferView>` (snapshot→`TransferView(role: receiver)` projection via `TransferProgressProjector`; `Completer<bool>` decision bridge with `onManifest`; `accept()`/`reject()` + `_rejectedByUser`; `start(transport)`; `cancel()`; `close()` disposes the use case) in `lib/features/receive/presentation/cubit/receive_transfer_cubit.dart` (depends on T017)
- [x] T019 [US2] Create `IncomingTransferDialog` (built from `IncomingOffer`; avatar badge + title/body + Nhận gradient / Từ chối; Cupertino/Material-appropriate; ARB copy; mono sizes) in `lib/features/receive/presentation/widgets/incoming_transfer_dialog.dart`

**Checkpoint**: the accept/reject gate works end-to-end at the cubit/dialog level (US2 independently testable); reject writes nothing.

---

## Phase 5: User Story 1 - Receive files from a paired peer (Priority: P1) 🎯 MVP

**Goal**: Full receive: enter code → connect → accept → live progress → complete (or partial/failure), wiring US3 + US2 into the navigation flow over the reused engine.

**Independent Test**: loopback round-trip (sender engine → receiver engine to a temp dir) confirms files arrive intact; the receive page renders preparing/transferring/done/partial from the snapshot stream; the full Home→Connect→Progress→Complete nav runs.

### Tests for User Story 1

- [x] T020 [P] [US1] **Loopback round-trip** for `startReceiveOnTransport` (real sender `startSendOnTransport` ↔ real receiver `startReceiveOnTransport` over a paired loopback `DataTransport`): single + multi-file arrive, hashes match, files exist at the temp destination; **a name-collision case (two same-named files) saves to distinct destinations without overwriting (FR-017)**; a forced mid-transfer drop yields a **partial** (earlier files kept, `.part` removed); existing `startReceive` loopback tests still green — in `test/core/services/transport/start_receive_on_transport_test.dart`
- [x] T021 [P] [US1] Widget test for `receive_transfer_page` in receiver role (preparing spinner; transferring %/speed/ETA/“tệp N/M”; done summary; **partial** “nhận X/N”; failure → error panel) in `test/features/receive/receive_transfer_page_test.dart`

### Implementation for User Story 1

- [x] T022 [US1] Create `receive_entry_page` coordinator (Home “Nhận” → push `connect` with `ConnectRequest(role: receiver)`; on `ConnectResult`, push `receiveProgress` with the core-typed `DataTransport` as `extra`) in `lib/features/receive/presentation/pages/receive_entry_page.dart` (replaces the placeholder `receive_page.dart`)
- [x] T023 [US1] Create `receive_transfer_page` (BlocProvider `ReceiveTransferCubit`; `start(transport)`; `BlocListener` → show `IncomingTransferDialog` on `awaitingDecision`, cancel-confirm dialog on Huỷ, route Reject→Home and recoverable failure→Connect/code-entry; bind shared `TransferProgressView`/`TransferCompleteView` receiver role) in `lib/features/receive/presentation/pages/receive_transfer_page.dart`
- [x] T024 [US1] Wire routes in `lib/core/router/app_router.dart`: `receiveProgress` (root navigator key, nav-less) + point the Home “Nhận” action at `receive_entry_page`; compose pairing + receive via core (no cross-feature import) — per [contracts/receive-flow-contract.md](contracts/receive-flow-contract.md) §5
- [x] T025 [US1] Register DI (`@injectable ReceiveTransferCubit`, `StartReceiveUseCase`; `ReceivedFilesService` singleton) and run `dart run build_runner build --delete-conflicting-outputs`; confirm `getIt` resolves the receive graph

**Checkpoint**: 🎯 **MVP** — a receiver can pair via code, accept, receive files to disk with live progress, and reach Complete; with #004 the full pair→send→receive loop works (modulo the deferred device smoke).

---

## Phase 6: User Story 4 - Save, open, and share received files (Priority: P2)

**Goal**: Received files persist in app storage with no permission prompt, and the Complete screen offers per-file Open + Share-all.

**Independent Test**: after a completed (loopback) receive, the Complete screen lists files; Open calls `ReceivedFilesService.open(path)`, Share calls `share(paths)`; no permission prompt occurs; a name collision saves a distinct file.

### Tests for User Story 4

- [x] T026 [P] [US4] Unit test for `ReceivedFilesServiceImpl` with mocktail (destinationDirectory under app docs `/SafeSend`; `share` builds `ShareParams` from paths; `open` maps a non-success result → failure `Result`) in `test/core/services/file/received_files_service_test.dart`
- [x] T027 [P] [US4] Widget test for `TransferCompleteView` receiver role (FileRow list; per-file **Mở** → `onOpen(path)`; **Chia sẻ** → `onShare(allPaths)`; partial summary shows received-vs-offered) in `test/features/receive/transfer_complete_receiver_test.dart`

### Implementation for User Story 4

- [x] T028 [US4] Wire the Complete actions in `receive_transfer_page` → `ReceivedFilesService.open`/`share` via the cubit/use case, `.fold` failures to an `AppToast` (e.g. “không mở được tệp”) in `lib/features/receive/presentation/pages/receive_transfer_page.dart`
- [x] T029 [US4] Add iOS Files visibility keys (`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`) to `ios/Runner/Info.plist` and (if a build conflict surfaces) an Android `FileProvider` entry — **deferred to the on-device build**; document in the tasks banner

**Checkpoint**: received files are reachable (Open/Share) with no permission prompt; collisions are non-destructive.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T030 [P] Haptics on connect / complete / fail in the receive flow (reuse the #004 helper)
- [x] T031 [P] Accessibility labels (code entry, accept/reject, progress, complete actions) + verify Reduce-Motion disables the connecting spinner (FR-027/FR-028)
- [x] T032 Run the full gate: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all pass) · `dart run bloc_tools:bloc lint .` (0) — fix any drift from the shared-UI lift
- [x] T033 Run [quickstart.md](quickstart.md) validation (loopback demo path + acceptance checklist: no permission prompt, nothing written before Accept, partial keeps only verified files, logs carry no paths/peer)
- [x] T034 **[DONE — device-validated 2026-06-25]** Two-physical-device receive smoke + full pair→send→receive→save MVP dogfood — validated on two iPhones (repeated back-to-back transfers stable) after the device-hardening pass (early-ICE buffering, signaling reconnect, flutter_webrtc teardown race, same-dir finalize, end-of-transfer channel-close race)

---

## Dependencies & Execution Order

### Phase dependencies
- **Setup (P1)** → no deps.
- **Foundational (P2)** → depends on Setup; **BLOCKS all stories**. Internal: T006 before T007; others [P].
- **US3 (P3)**, **US2 (P4)**, **US1 (P5)**, **US4 (P6)** → all depend on Foundational.
- **US1 integration (P5)** consumes US3 (Connect receiver branch → transport) and US2 (`ReceiveTransferCubit` + dialog); build US3 → US2 → US1.
- **US4 (P6)** depends on US1 (wires actions onto the Complete screen) + T005.
- **Polish (P7)** → after the desired stories.

### Story independence
- **US3** testable alone (Connect receiver widget + `joinWithCode`).
- **US2** testable alone (cubit decision bridge + dialog over a loopback manifest).

- **US1** is the integration MVP (needs US3 + US2 + Foundational).
- **US4** layers export onto US1's Complete screen; the service (T005) is unit-testable alone.

### Parallel opportunities
- Setup: T002, T003 in parallel.
- Foundational: T004, T005, T008, T009 in parallel; T006→T007 sequential.
- Each story's two test tasks ([P]) in parallel; `CodeInput` (T013) parallel to its test.

---

## Parallel Example: Foundational

```bash
# After Setup, launch the independent foundational tasks together:
Task: "Engine seam startReceiveOnTransport in lib/core/services/transport/transfer_engine.dart"   # T004
Task: "ReceivedFilesService + impl in lib/core/services/file/"                                      # T005
Task: "IncomingOffer model in lib/core/domain/transfer/incoming_offer.dart"                         # T008
Task: "Receive ARB strings + receive_failure_l10n mapper"                                           # T009
# Then T006 (TransferView lift) → T007 (widget lift) sequentially, then T010 (build_runner).
```

## Parallel Example: User Story 1

```bash
# Tests together:
Task: "Loopback round-trip for startReceiveOnTransport in test/core/services/transport/"            # T020
Task: "receive_transfer_page render test in test/features/receive/"                                 # T021
```

---

## Implementation Strategy

### MVP First (US3 → US2 → US1)
1. Phase 1 Setup → Phase 2 Foundational (CRITICAL — engine seam + shared-UI lift).
2. Phase 3 US3 (code entry) → Phase 4 US2 (accept/reject) → Phase 5 US1 (integration).
3. **STOP and VALIDATE**: loopback round-trip + the receive page; with #004 the pair→send→receive loop runs.

### Incremental Delivery
1. Setup + Foundational → foundation ready.
2. US3 → test → US2 → test → US1 → 🎯 MVP demo (loopback / two devices).
3. US4 (save/open/share) → test → demo.
4. Polish.

---

## Notes
- [P] = different files, no incomplete-task dependency. [Story] maps to spec.md user stories.
- The only merged-engine edit is additive (T004); the shared-UI lift (T006/T007) must keep #004's 107 tests green.
- Logs carry phase/error-type only — never file names/paths/peer/IP/SDP (Constitution I).
- Commit after each task or logical group; stop at any checkpoint to validate a story independently.
