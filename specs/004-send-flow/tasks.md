---
description: "Task list for #004 Send Flow (Gửi)"
---

# Tasks: Send Flow (Gửi)

**Input**: Design documents from `specs/004-send-flow/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Status**: ✅ **IMPLEMENTED (code)** 2026-06-24 — all 42 tasks done. `dart analyze lib test` = 0 · `flutter test` = 107 passed · `dart format` clean. Two-device send smoke (T041) remains the deferred device-only task.

**Tests**: INCLUDED — Constitution XII mandates `bloc_test` for all Cubits and widget tests for transfer-critical flows; the plan enumerates the required coverage.

> ⚠️ **Deferred (device-only)**: the **two-physical-device send smoke** (real NAT + multi-GB throughput) cannot run in CI — tracked as **T041**, expected to remain deferred until the first on-device build / merged #005.

**Org**: tasks grouped by user story. Build order among the three P1 stories: **US2 (selection) → US3 (pairing) → US1 (send integration = MVP)**, then P2 stories US4/US5. Each story is independently testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete-task dependency)
- **[Story]**: US1–US5 (user-story phases only)

---

## Phase 1: Setup (Shared Infrastructure)

- [x] T001 Add `file_picker: ^11.0.2` to `dependencies` in `pubspec.yaml` (verified pub.dev 2026-06-24, Constitution XV); run `flutter pub get`; confirm `pubspec.lock` updated and no `ios/Podfile.lock` churn
- [x] T002 [P] Add `connect = '/connect'` and `sendProgress = '/send/progress'` constants to `lib/core/constants/app_routes.dart`
- [x] T003 [P] Verify shared widgets exist in `lib/core/presentation/` (CodeBox, SegmentedTabs, FileRow/FileChip, Primary/Secondary/DangerButton, AppToast, FlowAppBar); list any missing for Phase 2

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: Must complete before any user story phase. Covers the engine seam, core services, shared models/widgets, and ARB.

- [x] T004 [P] Engine seam: refactor `TransferEngine.startSend` into `_initSession` + `_establish` + shared `_runSend`, and add `startSendOnTransport({required DataTransport transport, required TransferSession session})` (adopts the open transport, wires the `closed` watcher, runs `_runSend` from handshaking) in `lib/core/services/transport/transfer_engine.dart` — per [contracts/transfer-engine-seam.md](contracts/transfer-engine-seam.md)
- [x] T005 [P] Add `DataTransport? takeTransport()` to `PairingRepository` (`lib/features/pairing/domain/pairing_repository.dart`) + impl in `lib/features/pairing/data/pairing_repository_impl.dart` (clears `_transport` so `dispose()` won't double-close); expose it through `PairingCubit` in `lib/features/pairing/presentation/cubit/pairing_cubit.dart`
- [x] T006 [P] Create `FilePickerService` interface + `FilePickerServiceImpl` (file_picker 11 → `DiskFileSource` list; any-type, multi-select, `withData:false`; never logs paths) in `lib/core/services/file/file_picker_service.dart` and `lib/core/services/file/file_picker_service_impl.dart`
- [x] T007 [P] Create `SelectedFile` + `SendSelection` freezed models (count/totalBytes/isEmpty/toSources) in `lib/features/send/domain/models/send_selection.dart`
- [x] T008 [P] Create `SendTransferView` freezed model + a pure `fromSnapshot` projection helper (%, current file, items, peerLabel) in `lib/features/send/domain/models/send_transfer_view.dart`
- [x] T009 [P] Add reusable transfer widgets only if missing: gradient `ProgressBar` and `fileTypeColor(ext)` map (design table) in `lib/core/presentation/transfer/progress_bar.dart` and `lib/core/presentation/transfer/file_type_color.dart`
- [x] T010 [P] Add ARB strings (VI primary + EN) for send/connect copy and failure messages (`transferRejected`, `connectionLost`, `fileReadFailed`, declined/expired/retry labels) in `lib/l10n/arb/app_vi.arb` + `lib/l10n/arb/app_en.arb`; extend the failure→message mapping in `lib/features/pairing/presentation/pairing_failure_l10n.dart` (or add a parallel send mapper)
- [x] T011 Run `dart run build_runner build --delete-conflicting-outputs` (freezed + injectable + l10n) and confirm `dart analyze` is clean for the new foundation files

**Checkpoint**: engine seam + services + models + ARB ready — story implementation can begin.

---

## Phase 3: User Story 2 - Build and adjust the file selection (Priority: P1)

**Goal**: User opens Gửi, picks any-type files, sees per-file + total size, removes mistakes, and cannot continue with zero files.

**Independent Test**: open `/send`, add files, verify metadata + running total, remove one, confirm total updates, empty the tray → "Tiếp tục" disabled.

### Tests for User Story 2

- [x] T012 [P] [US2] `bloc_test` for `SendSelectionCubit` (add merges + recomputes count/total, removeAt updates, clear resets, picker-cancel = no change) in `test/features/send/send_selection_cubit_test.dart`
- [x] T013 [P] [US2] Widget test for the selection page (tray rows with name/type/size, header count + total in mono, empty-state CTA disabled) in `test/features/send/send_selection_page_test.dart`

### Implementation for User Story 2

- [x] T014 [P] [US2] `PickFilesUseCase` (wraps `FilePickerService`, returns `Result<List<FileSource>>`) in `lib/features/send/domain/usecases/pick_files_usecase.dart`
- [x] T015 [US2] `SendSelectionCubit extends AppCubit<SendSelection>` (starts loaded-empty; `addFiles`/`removeAt`/`clear`) in `lib/features/send/presentation/cubit/send_selection_cubit.dart` (depends on T007, T014)
- [x] T016 [US2] `SendSelectionPage` (Screen 02: FlowAppBar "Gửi file", accent-subtle banner "N mục đã chọn" + total, FileRow tray with remove, footer Thêm + Tiếp tục) replacing `lib/features/send/presentation/send_page.dart` → `lib/features/send/presentation/pages/send_selection_page.dart` + tray widgets under `lib/features/send/presentation/widgets/`
- [x] T017 [US2] Wire the `/send` route to `SendSelectionPage` in `lib/core/router/app_router.dart` (keep `parentNavigatorKey: rootKey`)

**Checkpoint**: file selection works and is demoable on its own.

---

## Phase 4: User Story 3 - Pair via a 6-digit code (Priority: P1)

**Goal**: Production Connect hub shows a 6-digit code + TTL countdown, drives pairing, and returns the open transport when a peer joins. Reusable by #005.

**Independent Test**: open `/connect` (sender role), see a well-formed code + counting-down expiry, disabled QR/Gần đây tabs; a joining peer advances to `connected` and the screen pops a `ConnectResult`.

### Tests for User Story 3

- [x] T018 [P] [US3] Widget test for `ConnectPage` (renders code + countdown, QR/Gần đây tabs disabled, `PairingFailed` → localized message + Retry, `PairingConnected` → pops `ConnectResult(transport)`) in `test/features/pairing/connect_page_test.dart`

### Implementation for User Story 3

- [x] T019 [P] [US3] `ConnectRequest({role})` + `ConnectResult({transport})` carriers in `lib/features/pairing/presentation/connect/connect_request.dart` and `connect_result.dart`
- [x] T020 [P] [US3] Connect widgets (SegmentedTabs Mã 6 số/QR/Gần đây with disabled tabs, `ssRadar` pulse, CodeBox row, "Hết hạn sau mm:ss" countdown from `PairingCode.remaining`, stubbed "Chia sẻ link mời") in `lib/features/pairing/presentation/connect/widgets/`
- [x] T021 [US3] `ConnectPage` (gradient-radar bg, FlowAppBar `x`, drives `PairingCubit.host()` for sender role, on connected `takeTransport()` → `context.pop(ConnectResult)`, on cancel/back `pop(null)` + dispose) in `lib/features/pairing/presentation/connect/connect_page.dart` (depends on T005, T019, T020)
- [x] T022 [US3] Wire the `/connect` route to `ConnectPage` (root navigator, returns `ConnectResult`) in `lib/core/router/app_router.dart`

**Checkpoint**: pairing hub works and returns a connected transport.

---

## Phase 5: User Story 1 - Send files to a paired peer (Priority: P1) 🎯 MVP

**Goal**: End-to-end send — selection → code → peer joins → files transfer over the reused channel with live progress → completion. Integrates US2 + US3.

**Independent Test**: with a cooperating receiver (loopback test / dev pairing-debug on a 2nd device / #005), pick files, get a code, peer joins+accepts, all files arrive intact, sender reaches the completion screen showing count/total/peer/elapsed.

### Tests for User Story 1

- [x] T023 [P] [US1] `startSendOnTransport` loopback round-trip (sender engine over a paired `LoopbackDataTransport` → receiver engine; files arrive, integrity matches, terminal `done`) in `test/core/services/transport/start_send_on_transport_test.dart`
- [x] T024 [P] [US1] `bloc_test` for `SendTransferCubit` (snapshot→`SendTransferView` projection incl. speed/ETA; `done`/`failed`/`cancelled` transitions; `cancel()` calls the engine) in `test/features/send/send_transfer_cubit_test.dart`
- [x] T025 [P] [US1] Widget test for the progress + complete views (%, speed, ETA, current-file in mono; generic peer label; complete summary count/total/elapsed) in `test/features/send/send_transfer_page_test.dart`

### Implementation for User Story 1

- [x] T026 [P] [US1] `StartSendUseCase` (builds `TransferSession.fromSources` → `engine.startSendOnTransport`; shares the engine instance with the cubit for `snapshots`) in `lib/features/send/domain/usecases/start_send_usecase.dart` (depends on T004)
- [x] T027 [US1] `SendTransferCubit extends AppCubit<SendTransferView>` (subscribes to `engine.snapshots`, projects via T008, computes smoothed speed/ETA per research R5, `start`/`cancel`) in `lib/features/send/presentation/cubit/send_transfer_cubit.dart` (depends on T008, T026)
- [x] T028 [US1] `SendTransferPage` progress view (Screen 05: "ĐANG GỬI" badge, 2 avatars + chevrons, % 64px mono, ProgressBar, speed/ETA row, current-file card with `ssSpin`) + complete view (Screen 06: gradient check, "Đã gửi N files · X MB tới <peerLabel> trong m:ss", file summary) in `lib/features/send/presentation/pages/send_transfer_page.dart` + widgets (depends on T009, T027)
- [x] T029 [US1] Wire `/send/progress` route + the navigation coordination in `SendSelectionPage` ("Tiếp tục" → `await push<ConnectResult>(connect, sender)` → `push(sendProgress, SendProgressArgs(sources, transport))`); add `SendProgressArgs` carrier (depends on T017, T022, T028)
- [x] T030 [US1] Complete-screen actions via `BlocListener`: success haptic, **Xong** → `context.go(home)`, **Gửi tiếp** → back to empty selection (`clear()`) in `send_transfer_page.dart`

**Checkpoint**: ⭐ full send loop works (the feature's headline value).

---

## Phase 6: User Story 4 - Cancel a send (Priority: P2)

**Goal**: Cancel while waiting (silent) and during transfer (confirm-gated); back-nav consistent.

**Independent Test**: reach waiting + transferring states; waiting cancel exits immediately with no lingering code; transferring cancel requires confirmation before aborting.

### Tests for User Story 4

- [x] T031 [P] [US4] Widget/bloc test: confirm-dialog gates transfer cancel (decline → continues; confirm → `cubit.cancel` + peer informed); waiting cancel is silent in `test/features/send/send_cancel_test.dart`

### Implementation for User Story 4

- [x] T032 [US4] Waiting cancel: Connect back/`x` → `pop(null)` ends pairing with no lingering code (verify against `ConnectPage` from T021) in `lib/features/pairing/presentation/connect/connect_page.dart`
- [x] T033 [US4] Transfer cancel: DangerButton "Hủy" + confirm dialog → `SendTransferCubit.cancel()`; back-nav while transferring routes through the same confirm (FR-021) in `lib/features/send/presentation/pages/send_transfer_page.dart`

**Checkpoint**: cancellation safe and consistent on both stages.

---

## Phase 7: User Story 5 - Understand & recover from a failed or declined send (Priority: P2)

**Goal**: Each failure (declined, expired, unreachable, timeout, room-full, rate-limited, connection-lost, file-read-fail) shows a distinct VI message + retry; retry preserves the selection.

**Independent Test**: induce each failure → distinct human-readable message + working Retry/Return; declined shows "đã từ chối", not a generic error; retry returns to pairing with the same files.

### Tests for User Story 5

- [x] T034 [P] [US5] Bloc/widget test: `AppFailure` → localized message mapping for each variant; declined outcome distinct; Retry pops back to selection with selection intact (FR-025a); no silent stall in `test/features/send/send_failure_test.dart`

### Implementation for User Story 5

- [x] T035 [US5] Failure view in `SendTransferPage` (localized message via the mapper, **Thử lại** → `pop` back to selection then re-continue, **Quay lại** → `go(home)`) in `lib/features/send/presentation/pages/send_transfer_page.dart`
- [x] T036 [US5] Ensure `transferRejected`/`connectionLost`/`fileReadFailed`/`roomExpired`/`signalingUnreachable`/`signalingTimeout`/`roomFull`/`rateLimited` all map to copy from T010; failure haptic; no path/peer/IP in any log (Constitution I) in the mapper + cubit error handling

**Checkpoint**: all failures are legible and recoverable.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T037 [P] Reduce-Motion: disable `ssRadar` (Connect) + `ssSpin` (progress) when reduce-motion is on, keep status textual (FR-029) in the Connect + progress widgets
- [x] T038 [P] Accessibility: screen-reader labels for the code, progress %/speed/ETA, and Cancel/Continue actions across `connect_page.dart` + `send_transfer_page.dart`
- [x] T039 [P] Run the gate: `dart format .`, `dart analyze` (0 issues), `flutter test` (all pass), `dart run bloc_tools:bloc lint .` (0)
- [x] T040 Run the [quickstart.md](quickstart.md) demo checklist (light + dark) and fix any UI/token drift
- [x] T041 Record the deferred **two-physical-device send smoke** in the tasks banner / on-device build backlog (real NAT + multi-GB throughput)
- [x] T042 Confirm `pubspec.lock` committed and reviewed; verify no unexpected transitive/native churn (Constitution XV)

---

## Dependencies & Execution Order

### Phase dependencies

- **Setup (P1)**: no deps.
- **Foundational (P2)**: depends on Setup; **blocks all stories**.
- **US2 → US3 → US1**: all P1; build in this order (US1 integrates US2's selection + US3's transport). US2 and US3 are independently testable and could be built in parallel by two devs; US1 depends on both.
- **US4, US5 (P2)**: depend on US1's `SendTransferPage`/`ConnectPage` existing.
- **Polish**: after the desired stories.

### Within a story

- Tests written first and failing → models → use cases → cubits → pages → route wiring.

### Parallel opportunities

- Setup: T002, T003 in parallel.
- Foundational: T004–T010 are mostly different files → parallel (T011 build_runner after them).
- US2 tests T012/T013 parallel; US3 T018 alone; US1 tests T023/T024/T025 parallel.
- US2 and US3 can proceed in parallel (different feature trees) once Foundational is done.

---

## Parallel Example: Foundational

```bash
# After Setup, launch the independent foundation files together:
Task: T004 engine seam in lib/core/services/transport/transfer_engine.dart
Task: T005 takeTransport in features/pairing/{domain,data,presentation}
Task: T006 FilePickerService in lib/core/services/file/
Task: T007 SendSelection model
Task: T008 SendTransferView model
Task: T010 ARB strings + failure mapper
# then: T011 build_runner
```

---

## Implementation Strategy

### MVP (the headline send loop)

1. Phase 1 Setup → Phase 2 Foundational.
2. Phase 3 US2 (selection) → Phase 4 US3 (pairing) → Phase 5 US1 (send integration).
3. **STOP & VALIDATE**: run the loopback round-trip + the demo checklist with the dev pairing-debug receiver. This is the demoable MVP.

### Incremental delivery

4. Add US4 (cancel) → validate.
5. Add US5 (failure/recovery) → validate.
6. Polish (reduce-motion, a11y, gate, quickstart).
7. Deferred: two-device send smoke (T041) on the first on-device build / with #005.

---

## Notes

- [P] = different files, no incomplete-task dependency.
- Reuse `core/presentation` shared widgets — never duplicate markup (Constitution VI).
- Engine edits are additive: `startSend` + its loopback tests stay green (Constitution XII).
- No file paths / peer ids / IPs / SDP-ICE in any log (Constitution I); user copy from ARB only (XIV).
- Commit after each task or logical group; stop at any checkpoint to validate a story independently.
