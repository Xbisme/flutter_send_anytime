---
description: "Task list for #006 Lịch sử (History) implementation"
---

# Tasks: Lịch sử (History)

**Input**: Design documents from `/specs/006-history/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/)

**Tests**: INCLUDED — Constitution XII mandates unit/BLoC/widget tests for state, data transforms, and transfer-critical flows. Each story carries its own tests.

**Organization**: Tasks are grouped by user story (spec.md priorities) for independent implementation and testing.

> ## Status banner
> ✅ **IMPLEMENTED (code).** 58/59 tasks done; **T058 (on-device quickstart pass + first `pod install`) deferred** — device-only. Local feature — **no two-device smoke test required** (no P2P surface); all paths CI-tested via drift `NativeDatabase.memory()`.
> **Gate**: `dart format` clean · `dart analyze lib test` = **0** · `flutter test` = **167 passed** · bloc-lint CLI not installed (deferred since #001). Use **`dart analyze`** — `flutter analyze` crashes on this detached-HEAD checkout.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1–US6 (user-story tasks only)
- Every task names exact file paths.

## Path Conventions

Flutter feature-first (Constitution XI): shared persistence in `lib/core/`, feature UI in `lib/features/history/`, tests mirror under `test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the drift toolchain so the persistence layer can be built.

- [X] T001 Add `drift: ^2.34.0` and `drift_flutter: ^0.3.0` under `dependencies`, and `drift_dev: ^2.34.1` under `dev_dependencies` in `pubspec.yaml` (versions per [research.md](research.md) Decision 1); run `flutter pub get` and commit the updated `pubspec.lock`.
- [X] T002 [P] Confirm `analysis_options.yaml` excludes generated drift output (`**.g.dart` already excluded); add `lib/core/data/database/**.g.dart` to the exclude globs only if analysis flags generated code.

**Checkpoint**: drift available; `dart run build_runner build` succeeds on an empty schema.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared `core/` history store (domain + drift DB + repository + DI) that EVERY user story depends on. ⚠️ No story work begins until this is complete.

### Core domain (`lib/core/domain/history/`)

- [X] T003 [P] Create `lib/core/domain/history/transfer_history_enums.dart` — `TransferDirection {sent, received}`, `TransferRecordStatus {completed, partial, failed, cancelled}`, `PairingMethod {sixDigitCode, qr, shareLink, nearby}` (reserve future values per FR-007).
- [X] T004 [P] Create `lib/core/domain/history/transfer_record.dart` — freezed `TransferRecord` + `RecordedFile` (fields per [data-model.md](data-model.md): id, direction, peerLabel, status, pairingMethod, fileCount, totalBytes, createdAt, files; RecordedFile: name, mimeType?, size, path?, included).
- [X] T005 [P] Create `lib/core/domain/history/history_filter.dart` — freezed `HistoryFilter` (direction?, from?, to?, query?) with `HistoryFilter.none` and `isActive`.
- [X] T006 Create `lib/core/domain/history/transfer_history_repository.dart` — the `TransferHistoryRepository` interface exactly per [contracts/transfer-history-repository.md](contracts/transfer-history-repository.md) (record / watch / watchRecent / getById / deleteById / clearAll).

### drift schema (`lib/core/data/`)

- [X] T007 [P] Create `lib/core/data/database/tables/transfer_records_table.dart` — drift `TransferRecords` table (id PK text, direction, peer_label, status, pairing_method, file_count, total_bytes, created_at indexed) per [data-model.md](data-model.md).
- [X] T008 [P] Create `lib/core/data/database/tables/transfer_record_files_table.dart` — drift `TransferRecordFiles` table (id PK autoinc, record_id FK→records cascade + indexed, name, mime_type?, size, path?, included default true, position).
- [X] T009 Create `lib/core/data/database/app_database.dart` — `@DriftDatabase(tables: [...])` `AppDatabase`, `schemaVersion = 1`, `MigrationStrategy(onCreate: m.createAll(), beforeOpen: enable PRAGMA foreign_keys)`, connection via `drift_flutter` `driftDatabase(name: 'safe_send')` (depends on T007, T008).
- [X] T010 Create `lib/core/data/daos/transfer_history_dao.dart` — `@DriftAccessor` DAO: `insertRecord` (transaction: parent + child rows), `watchAll(HistoryFilter)` (WHERE direction + created_at range + LIKE on peer_label/EXISTS child name; ORDER BY created_at DESC), `watchRecent(int)`, `getById`, `deleteById`, `clearAll` (depends on T009).
- [X] T011 Run `dart run build_runner build --delete-conflicting-outputs` to generate `app_database.g.dart` + history `*.freezed.dart` (depends on T003–T010).

### Repository + DI

- [X] T012 Create `lib/core/data/transfer_history_repository_impl.dart` — `@LazySingleton(as: TransferHistoryRepository)` mapping drift rows ↔ `TransferRecord`/`RecordedFile` (enum name (de)serialize with safe-default fallback), wrapping every call in `Result<T>` (try/catch → `AppFailure.fileWriteFailed`/`fileReadFailed`/`unknown`) (depends on T006, T010, T011).
- [X] T013 Create `lib/core/di/database_module.dart` — `@module` providing `AppDatabase` as `@lazySingleton` (with disposal) so injectable can construct the DAO + repository; run build_runner to refresh `injection.config.dart` (depends on T009, T012).

### Foundational tests

- [X] T014 [P] Create `test/core/data/transfer_history_dao_test.dart` — open `AppDatabase` over `NativeDatabase.memory()`; assert insert→`watchAll`→`watchRecent`→filter(direction/date/query)→`deleteById` (FK cascade removes file rows)→`clearAll` (depends on T010, T011).
- [X] T015 [P] Create `test/core/data/transfer_history_repository_test.dart` — row↔domain mapping both directions, `Result.failure` on DB error, enum unknown-name fallback (depends on T012).

**Checkpoint**: The store works end-to-end in tests. User stories can now begin (in parallel if staffed).

---

## Phase 3: User Story 1 - Browse past transfers (Priority: P1) 🎯 MVP

**Goal**: A Lịch sử tab listing all records newest-first, grouped by local day, with direction-colored entries and an empty state.

**Independent Test**: Seed the repository (in-memory DB or mocked stream) with a sent and a received record across two days → open the tab → both appear under day headers, visually distinguished, newest-first; with no records, the empty state shows.

### Tests for User Story 1

- [X] T016 [P] [US1] Create `test/features/history/history_cubit_test.dart` — `HistoryCubit` emits loading→loaded for a record stream; loaded-empty maps to the empty state; ordering newest-first (mock `WatchHistoryUseCase`).
- [X] T017 [P] [US1] Create `test/features/history/history_page_test.dart` — widget test: day-section headers ("Hôm nay"/date), direction-colored rows (sent vs received), and the never-had-history empty state.

### Implementation for User Story 1

- [X] T018 [P] [US1] Create `lib/features/history/domain/usecases/watch_history_usecase.dart` — `@injectable`, wraps `TransferHistoryRepository.watch(filter)`.
- [X] T019 [US1] Create `lib/features/history/presentation/cubit/history_cubit.dart` — `@injectable` 4-state `AppCubit`, holds current `HistoryFilter` (default `none`), subscribes to `watch`, emits day-grouped view model; close the subscription on `close()` (depends on T018).
- [X] T020 [P] [US1] Create `lib/features/history/presentation/widgets/history_day_header.dart` and `history_record_row.dart` — day section header (intl relative-day) + a row reusing `FileRow`/token patterns with a direction-colored avatar (sent=`accent`, received=`info`), size in JetBrains Mono tabular (depends on nothing in this story; pure widgets).
- [X] T021 [US1] Replace the #001 placeholder in `lib/features/history/presentation/history_page.dart` — provide `HistoryCubit`, render the grouped sliver list + `AppEmptyView` empty state; wire into the existing `AppRoutes.history` shell branch (no router change) (depends on T019, T020).
- [X] T022 [P] [US1] Add history-list ARB strings to `lib/l10n/arb/app_vi.arb` (primary) + `app_en.arb` (title, empty-state copy, "Hôm nay"/"Hôm qua", direction labels) with `@description`; run `flutter gen-l10n`.

**Checkpoint**: The Lịch sử tab renders real records (seeded) — independently demoable.

---

## Phase 4: User Story 2 - Record every finished transfer (Priority: P1)

**Goal**: One record written on every agreed-and-started terminal transfer (completed/partial/failed/cancelled) from both Send and Receive; pairing-stage failures excluded (FR-001).

**Independent Test**: Drive a terminal `TransferView` through the send and receive paths to each status → exactly one correctly-mapped `record()` call per transfer; a pairing-stage failure records nothing; restart shows persistence.

### Tests for User Story 2

- [X] T023 [P] [US2] Create `test/features/send/send_records_history_test.dart` — terminal `done`/`partial`/`cancelled`/`failed` each produces one record with `direction=sent`, source paths, correct status; no record before a `startSend` (mock `RecordTransferUseCase`).
- [X] T024 [P] [US2] Create `test/features/receive/receive_records_history_test.dart` — accepted transfer reaching terminal records `direction=received` with finalPaths + offered totals; partial maps to `partial`; reject-before-accept and pairing failure record **nothing** (FR-001).

### Implementation for User Story 2

- [X] T025 [P] [US2] Create `lib/core/domain/history/usecases/record_transfer_usecase.dart` — `@injectable` `RecordTransferUseCase` wrapping `repository.record` per [contracts/transfer-history-repository.md](contracts/transfer-history-repository.md).
- [X] T026 [P] [US2] Create `lib/features/send/domain/send_history_mapper.dart` — map terminal `TransferView` + the started `List<FileSource>` → `TransferRecord` (status mapping per [research.md](research.md) Decision 3; `path` from `DiskFileSource.path`; `included` per item; **stamp `createdAt = DateTime.now()` and generate a fresh `id` (uuid) at the terminal call site**).
- [X] T027 [P] [US2] Create `lib/features/receive/domain/receive_history_mapper.dart` — map terminal `TransferView` → `TransferRecord` (`path` from item `finalPath`; `fileCount`/`totalBytes` = offered manifest totals; **stamp `createdAt = DateTime.now()` and generate a fresh `id` (uuid) at the terminal call site**).
- [X] T028 [US2] Edit `lib/features/send/presentation/cubit/send_transfer_cubit.dart` — inject `RecordTransferUseCase`, and on the existing terminal branch call it once via the send mapper; a `Result.failure` only logs (`AppLogger`) and never alters the user-visible outcome (depends on T025, T026).
- [X] T029 [US2] Edit `lib/features/receive/presentation/cubit/receive_transfer_cubit.dart` — inject `RecordTransferUseCase`, record once on the terminal branch (only when a transfer was accepted/started, not on reject/pairing failure) via the receive mapper; failure logs only (depends on T025, T027).
- [X] T030 [US2] Run build_runner to refresh `injection.config.dart` for the new use case + cubit constructor changes (depends on T028, T029).

**Checkpoint**: Live Send/Receive now populate the Lịch sử tab; US1 + US2 = the working MVP loop for History.

---

## Phase 5: User Story 3 - Inspect a transfer's details (Priority: P2)

**Goal**: Tap a record → a detail page with the full per-file list and all recorded metadata, reachable record actions.

**Independent Test**: With a multi-file record present, tap it → detail shows every file (name/type/size), totals, exact date/time, status, pairing method; back returns to the list.

### Tests for User Story 3

- [X] T031 [P] [US3] Create `test/features/history/history_detail_page_test.dart` — renders the full file list + metadata from a passed `TransferRecord`; partial record shows which files landed (`included`).

### Implementation for User Story 3

- [X] T032 [US3] Add `historyDetail` to `lib/core/constants/app_routes.dart` and register the route in `lib/core/router/app_router.dart` (root-level, receives a core-typed `TransferRecord` via `extra`).
- [X] T033 [P] [US3] Create `lib/features/history/domain/usecases/get_history_detail_usecase.dart` — `@injectable`, wraps `repository.getById` (fallback when `extra` is absent).
- [X] T034 [US3] Create `lib/features/history/presentation/history_detail_page.dart` — render direction, peer label, full `FileRow` list, totals, date/time (intl), status, pairing method; place the per-record action slots (re-send/open/delete added in US5) (depends on T032).
- [X] T035 [US3] Wire `history_record_row.dart` tap → `context.push(AppRoutes.historyDetail, extra: record)` (depends on T032, US1 T020).
- [X] T036 [P] [US3] Add detail-page ARB strings (labels for metadata fields, pairing-method names) to `app_vi.arb` + `app_en.arb`; run `flutter gen-l10n`.

**Checkpoint**: Records are fully inspectable.

---

## Phase 6: User Story 4 - Search and filter history (Priority: P2)

**Goal**: Narrow the list by text query (peer/file names) and by direction and date range, with a distinct no-results state.

**Independent Test**: With records spanning both directions/days/peers, a query and each filter narrows correctly; clearing restores the full list; an unmatched filter shows "no results" (distinct from empty).

### Tests for User Story 4

- [X] T037 [P] [US4] Add to `test/features/history/history_cubit_test.dart` — `setQuery`/`setDirection`/`setDateRange` re-emit filtered lists; active-filter-with-zero-results maps to the no-results state; clearing restores full list.
- [X] T038 [P] [US4] Create `test/features/history/history_filter_bar_test.dart` — widget test: search input, direction segmented control, date filter trigger update the cubit; no-results state renders.

### Implementation for User Story 4

- [X] T039 [US4] Extend `lib/features/history/presentation/cubit/history_cubit.dart` — `setQuery`, `setDirection`, `setDateRange`, `clearFilters` mutate the held `HistoryFilter` and re-subscribe `watch`; expose `isFilterActive` to distinguish empty vs no-results (depends on US1 T019; DAO filter support already in T010).
- [X] T040 [P] [US4] Create `lib/features/history/presentation/widgets/history_filter_bar.dart` — `SearchPill` + direction `SegmentedTabs`/chips + a date-range trigger (platform date picker), all driving the cubit.
- [X] T041 [US4] Render the filter bar in `history_page.dart` and add the no-results `AppEmptyView` variant (depends on T039, T040).
- [X] T042 [P] [US4] Add search/filter ARB strings (search placeholder, direction filter labels, date filter, no-results copy) to `app_vi.arb` + `app_en.arb`; run `flutter gen-l10n`.

**Checkpoint**: History is searchable and filterable.

---

## Phase 7: User Story 5 - Act on a past transfer (Priority: P2)

**Goal**: Re-send (all-or-nothing), open a received file, delete a single record, clear all (with confirmation) — record-only delete never touches files on disk.

**Independent Test**: Re-send a sent record whose files exist → Send opens pre-filled; missing files → re-send unavailable. Open a received file → system viewer; moved file → "unavailable". Delete one → gone after restart. Clear all → confirm → empty.

### Tests for User Story 5

- [X] T043 [P] [US5] Create `test/features/history/history_actions_test.dart` — `DeleteRecordUseCase`/`ClearHistoryUseCase` call through; **after `deleteById`, a referenced on-disk temp file still exists** (FR-025 record-only delete); re-send availability = all source paths exist (all-or-nothing FR-021); open-unavailable when path missing.

### Implementation for User Story 5

- [X] T044 [P] [US5] Create `lib/features/history/domain/usecases/delete_record_usecase.dart` and `clear_history_usecase.dart` — `@injectable`, wrap `repository.deleteById` / `clearAll`.
- [X] T045 [P] [US5] Create `lib/features/history/domain/usecases/resend_availability_usecase.dart` (or a pure helper) — given a `TransferRecord`, return whether every `RecordedFile.path` exists (`File(path).existsSync()`), used to enable/disable re-send (FR-020/021).
- [X] T046 [US5] Add delete (single) + clear-all to `history_cubit.dart`/page — swipe/menu delete on a row, `DangerButton` clear-all with a platform confirm dialog; refresh is automatic via drift streams (depends on T044, US1 T019/T021).
- [X] T047 [US5] Add open + re-send to `history_detail_page.dart` — open received file via `open_filex` with an "file no longer available" `AppToast` on failure/missing; re-send (sent records, when available) reconstructs `List<DiskFileSource>` and hands off into the Send flow via the **existing #004 core-typed entry** — first confirm the exact route constant and its `extra` contract (the #004 `List<FileSource>` handoff into `AppRoutes.connect`/send selection) and pin it here; no `features/send` import of internals (depends on T034, T045).
- [X] T048 [P] [US5] Add actions/confirmation ARB strings (Gửi lại, Mở, Chia sẻ, Xoá, Xoá tất cả, confirm dialog copy, unavailable messages) to `app_vi.arb` + `app_en.arb`; run `flutter gen-l10n`.

**Checkpoint**: All per-record actions work; delete/clear leave files on disk untouched.

---

## Phase 8: User Story 6 - See recent activity on Home (Priority: P3)

**Goal**: Home's recent area shows the real most-recent transfers from the same store (replacing #001 mock), tappable into the same detail.

**Independent Test**: After a transfer, Home shows it in the recent area (no mock data); none → empty/encouraging state; tap → history detail.

### Tests for User Story 6

- [X] T049 [P] [US6] Create `test/features/home/home_recent_history_test.dart` — the real Home data source maps `watchRecent` records → `TransferGroupModel` recent section; empty list → empty recent state.

### Implementation for User Story 6

- [X] T050 [P] [US6] Create `lib/features/home/domain/usecases/watch_recent_transfers_usecase.dart` — `@injectable`, wraps `repository.watchRecent(limit)`.
- [X] T051 [US6] Create `lib/features/home/data/home_history_data_source.dart` and wire `HomeCubit` to source the recent-transfers section from `watch_recent_transfers_usecase` while preserving the `HomeDashboard` contract (FR-008 seam); **retain `HomePlaceholderDataSource` for the still-mock media/stat sections** (only the recent-transfers section goes live) and **run build_runner** to refresh `injection.config.dart` for the changed `HomeCubit` constructor (depends on T050).
- [X] T052 [US6] Make Home recent items navigate to `AppRoutes.historyDetail` with the core-typed record (depends on US3 T032).
- [X] T053 [P] [US6] Update Home recent empty-state copy in ARB if new strings are needed; run `flutter gen-l10n`.

**Checkpoint**: All six stories independently functional.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T054 [P] Add accessibility labels (Semantics) to history rows, filter controls, actions, and confirmation dialogs (FR-031).
- [X] T055 [P] Verify ARB parity between `app_vi.arb` and `app_en.arb` (every key in both, all have `@description`); VI is primary (Constitution XIV).
- [X] T056 [P] Add a schema-version guard test scaffold `test/core/data/app_database_schema_test.dart` — assert `schemaVersion == 1` and `onCreate` builds all tables, reserving the structure for future migration tests (Constitution IX).
- [X] T057 Run the full gate: `dart format .` · `dart analyze lib test` (0 issues) · `flutter test` (all pass) · bloc lint (0).
- [ ] T058 Execute [quickstart.md](quickstart.md) manual verification (record → list → detail → search/filter → re-send/open/delete/clear → restart persistence → Home recent). **Perf smoke (SC-008)**: seed ~500 records (in-memory DB or a debug helper) and confirm the list scrolls and search/filter stay smooth.
- [X] T059 [P] Update `.claude/claude-app/changelog.md` + `project-context.md` + `CLAUDE.md` (mark #006 implemented; note drift deps + `core/data/` layer + the one additive #004/#005 edit; device build note: `ios/Podfile.lock` churn from sqlite3 pod).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → no deps.
- **Foundational (P2)** → after Setup. **BLOCKS all stories** (the store + repository + DI).
- **US1 Browse (P3)** & **US2 Record (P4)** → after Foundational; both P1, independently testable. US1 demoable via seeded data; US2 populates it live.
- **US3 (P5)** → after Foundational; reads US1's row widget for the tap-in (T035) but detail itself is independent.
- **US4 (P6)** → after US1 (extends the list cubit/page).
- **US5 (P7)** → after US1 (+US3 for detail-hosted actions).
- **US6 (P8)** → after Foundational; uses US3's detail route (T052).
- **Polish (P9)** → after all desired stories.

### Within Each Story

- Tests `[P]` first (they fail until impl lands), then domain use case → cubit → widgets → page wiring → ARB.
- build_runner re-runs after any freezed/drift/injectable change (T011, T030).

### Parallel Opportunities

- Setup: T002 ∥ T001 tail.
- Foundational: domain T003/T004/T005 ∥; tables T007/T008 ∥; tests T014/T015 ∥ (after their deps).
- Per story: the two test tasks ∥; ARB and pure-widget tasks ∥ with use-case tasks.
- Across stories: once Foundational is done, US1/US2/US3/US6 can be split across developers (US4/US5 build on US1).

---

## Parallel Example: Foundational domain + schema

```bash
# Domain entities (independent files):
Task: T003 enums in lib/core/domain/history/transfer_history_enums.dart
Task: T004 TransferRecord in lib/core/domain/history/transfer_record.dart
Task: T005 HistoryFilter in lib/core/domain/history/history_filter.dart
# drift tables (independent files):
Task: T007 TransferRecords table
Task: T008 TransferRecordFiles table
# (then T009 AppDatabase, T010 DAO, T011 build_runner serialize)
```

## Parallel Example: User Story 1 tests

```bash
Task: T016 HistoryCubit test in test/features/history/history_cubit_test.dart
Task: T017 history_page widget test in test/features/history/history_page_test.dart
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Phase 1 Setup → Phase 2 Foundational (the store).
2. Phase 3 US1 (browse, seeded) → validate the tab renders/groups/empties.
3. Phase 4 US2 (recording) → drive a real Send/Receive → records appear and persist.
4. **STOP & VALIDATE**: the History MVP (record + browse) works end-to-end; demo.

### Incremental Delivery

US3 detail → US4 search/filter → US5 actions → US6 Home recent → Polish. Each adds value without breaking prior stories.

---

## Notes

- `[P]` = different files, no incomplete-task dependency.
- The **only** edits to merged #004/#005 code are T028/T029 (inject + call the recorder) — additive, mirroring prior seams.
- No two-device smoke test (local feature, no P2P surface).
- Commit after each task or logical group; keep generated `*.g.dart`/`*.freezed.dart` + `pubspec.lock`/`Podfile.lock` in the commit that introduces them.
