# Implementation Plan: Lịch sử (History)

**Branch**: `006-history` | **Date**: 2026-06-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-history/spec.md`

## Summary

History (#006) adds local persistence and browsing of finished transfers, closing the loop opened by Send (#004) and Receive (#005). The technical approach: a **drift (SQLite) database lives in `core/data/`** (it is consumed by four features — Send, Receive, History, Home — so it cannot live inside any one feature without breaking the no-cross-feature-import rule). A `core/`-owned **`TransferHistoryRepository`** exposes write (record) and read (watch/query/delete) over the DB. The Send and Receive flows record exactly one `TransferRecord` when an **agreed-and-started** transfer reaches a terminal state, via a thin core write use case injected into their existing terminal-detection points (the only edit to merged #004/#005 code — additive, mirroring prior seams). The new `features/history/` provides the Lịch sử tab (day-grouped list, search/filter, detail) and the per-record actions (re-send / open / delete / clear all). `features/home/` swaps its placeholder recent-transfers data for the same store via its pre-built FR-008 seam. All UI reuses the existing design tokens and shared widgets; copy is VI-primary ARB.

## Technical Context

**Language/Version**: Dart `^3.11.0` (Flutter latest stable) — matches `pubspec.yaml` `environment.sdk`.
**Primary Dependencies**: `drift ^2.34.0` (SQLite ORM + codegen) + `drift_flutter ^0.3.0` (DB connection, native libs, path_provider, background isolate) as runtime deps; `drift_dev ^2.34.1` as a dev dep alongside the existing `build_runner ^2.15.0`. Reuses existing `flutter_bloc`, `injectable`/`get_it`, `go_router`, `intl`, `open_filex`, `share_plus`, and the #004 `file_picker`/`FileSource` send path for re-send.
**Storage**: drift over SQLite, on-device only. Two tables: `transfer_records` (1) ──< `transfer_record_files` (N). Schema version 1 (initial; future changes add non-destructive migrations per Constitution IX). No cloud, no sync.
**Testing**: `flutter_test` + `bloc_test` + `mocktail`; DAO/repository tests run against drift's in-memory `NativeDatabase.memory()` (host libsqlite3, no device needed). Cubit tests mock the repository.
**Target Platform**: iOS 13+ / Android API 26+ (sqlite3_flutter_libs supports both well below these floors).
**Project Type**: Mobile app (Flutter, feature-first Clean Architecture).
**Performance Goals**: History list + search/filter stay responsive (no perceptible lag, SC-008) at ≥ several hundred records. The list **renders** lazily (slivers build only visible rows); the filtered result set is held in memory as a `List` (acceptable at this scale — hundreds, not millions). True offset/limit paging is not designed for #006; if history ever outgrows this, add `limit`/`offset` to `watch` then.
**Constraints**: `lib/core/` MUST NOT import `lib/features/`; features MUST NOT import each other; offline-only; no runtime permission (delete is record-only — files stay on disk; storage cleanup deferred to #010).
**Scale/Scope**: One new feature module + one new `core/data/` layer; ~6 user stories; ~5 ARB string groups; one additive edit to each of #004/#005 cubits.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Compliance |
|---|---|
| **I. Privacy-First P2P** | History persists **metadata only** (peer label, file names/types/sizes/count, totals, timestamp, direction, status, pairing method, local file paths) — never file *contents* (Principle II explicitly permits this). No codes/IPs/secrets stored or logged. ✅ |
| **II. Direct Transfer & Data Minimization** | Records the minimum metadata; stores a path reference, not bytes. Record-only delete keeps the store from coupling to file lifecycle. ✅ |
| **III. BLoC 4-state** | `HistoryCubit` (+ optional detail) use the freezed 4-state `AppCubit<T>`; recording triggered from existing cubits' terminal handling; side effects via `BlocListener`. ✅ |
| **IV. Code Quality** | `very_good_analysis` zero-warning; explicit types; drift-generated code is excluded from lints per existing `analysis_options`. ✅ |
| **V. Result\<T\>** | Repository methods return `Result<T>`; failures map to `AppFailure` (`fileWriteFailed`/`fileReadFailed`/`unknown`); a new minimal failure surface for DB errors reuses existing variants. ✅ |
| **VI. Design System** | Reuses tokens + shared widgets (`FileRow`, `SearchPill`, `SegmentedTabs`, `StatTile`, `DangerButton`, `AppToast`, `AppEmptyView`); direction colors use semantic aliases (sent=`accent`, received=`info`); sizes/dates use JetBrains Mono tabular figures. Screen 07 per `ui-design-context.md`. ✅ |
| **VII. Cross-Platform** | Platform-appropriate confirm dialog for clear-all; open/share via existing `open_filex`/`share_plus`; a11y labels (FR-031). ✅ |
| **VIII. Transport & Signaling** | **No transport/signaling/protocol change.** History observes the existing terminal transfer state only. ✅ |
| **IX. Transfer Reliability & Integrity** | drift migrations are non-destructive; schema v1 with a `MigrationStrategy` + a schema-version test scaffold so future versions add migration tests. Records written only on a true terminal state (FR-001). ✅ |
| **X. go_router** | New `AppRoutes.historyDetail`; navigation via `context.push` with a core-typed `extra` (`TransferRecord`); no `Navigator.of` direct use. ✅ |
| **XI. Feature-First Modularity** | drift DB + repository in `core/` (cross-feature); `features/history/` self-contained; Send/Receive/Home depend on the **core** repository via use cases — never on each other. Repo-interface-in-domain / impl-in-data preserved. ✅ |
| **XII. Testing** | Unit (DAO/repo mapping, day-grouping, filter), BLoC (`HistoryCubit` list/search/filter/empty, record-on-terminal), widget (list grouping, empty/no-results, detail, clear-all confirm). No two-device dependency (local feature) — no smoke test needed. ✅ |
| **XIII. Simplicity & YAGNI** | One DB, two tables, one repository; no generic query builder, no retention config, no file-deletion path (all deferred). Re-send is all-or-nothing (no subset selection UX). ✅ |
| **XIV. i18n** | All strings ARB (VI primary + EN), `@description` annotations; `intl` for dates/sizes/relative-day headers. ✅ |
| **XV. Dependency Hygiene** | drift/drift_flutter/drift_dev versions fetched from pub.dev 2026-06-25 (see research.md); SDK floors verified (≥3.10 vs our 3.11). `sqlite3_flutter_libs` is transitive (not hand-pinned). Native pod/`.so` churn noted for the device build. ✅ |

**Result: PASS.** No violations; Complexity Tracking not required.

## Project Structure

### Documentation (this feature)

```text
specs/006-history/
├── plan.md              # This file
├── spec.md              # Feature spec (+ Clarifications)
├── research.md          # Phase 0 — package + architecture decisions
├── data-model.md        # Phase 1 — drift schema + domain entities
├── quickstart.md        # Phase 1 — build/run/test steps
├── contracts/
│   └── transfer-history-repository.md   # core repository + write-hook contract
└── checklists/
    └── requirements.md  # spec quality checklist (from /speckit.specify)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── data/                                   # NEW — shared persistence (cross-feature)
│   │   ├── database/
│   │   │   ├── app_database.dart               # drift @DriftDatabase, schemaVersion 1, MigrationStrategy
│   │   │   ├── app_database.g.dart             # generated (build_runner)
│   │   │   └── tables/
│   │   │       ├── transfer_records_table.dart
│   │   │       └── transfer_record_files_table.dart
│   │   ├── daos/
│   │   │   └── transfer_history_dao.dart        # insert(tx) / watch / search / delete / clearAll
│   │   └── transfer_history_repository_impl.dart # @LazySingleton(as: TransferHistoryRepository)
│   ├── domain/
│   │   ├── history/                             # NEW — core history capability
│   │   │   ├── transfer_record.dart            # entity + RecordedFile (freezed)
│   │   │   ├── transfer_history_enums.dart     # TransferDirection / TransferRecordStatus / PairingMethod
│   │   │   ├── history_filter.dart             # direction? + dateRange? + query?
│   │   │   ├── transfer_history_repository.dart # interface (write + read)
│   │   │   └── usecases/
│   │   │       └── record_transfer_usecase.dart # write half — injected by Send & Receive
│   │   └── ...                                  # (existing transfer/pairing domain)
│   └── constants/app_routes.dart               # + historyDetail
├── features/
│   ├── history/                                 # NEW feature module
│   │   ├── domain/usecases/                     # WatchHistory / GetDetail / DeleteRecord / ClearHistory
│   │   ├── presentation/
│   │   │   ├── cubit/history_cubit.dart         # 4-state; holds HistoryFilter; watches repo
│   │   │   ├── history_page.dart                # replaces #001 placeholder (day-grouped list)
│   │   │   ├── history_detail_page.dart
│   │   │   └── widgets/                         # day section header, history row, filter bar
│   │   └── ...
│   ├── home/
│   │   ├── data/home_history_data_source.dart   # NEW — recent transfers from the core repo
│   │   └── presentation/cubit/home_cubit.dart   # wires recent section to real data (FR-008 seam)
│   ├── send/presentation/cubit/send_transfer_cubit.dart      # + record on terminal (additive)
│   ├── send/domain/.../send_history_mapper.dart  # TransferView + sources → TransferRecord
│   └── receive/presentation/cubit/receive_transfer_cubit.dart # + record on terminal (additive)
│       └── (receive_history_mapper.dart)         # TransferView + finalPaths → TransferRecord
└── l10n/arb/{app_vi.arb, app_en.arb}            # + history strings

test/
├── core/data/transfer_history_dao_test.dart            # in-memory drift round-trip
├── core/data/transfer_history_repository_test.dart     # mapping + Result
├── features/history/history_cubit_test.dart            # list / search / filter / empty / no-results
├── features/history/history_page_test.dart             # grouping + empty + clear-all confirm
├── features/history/history_detail_page_test.dart
├── features/send/send_records_history_test.dart        # records one TransferRecord on terminal
└── features/receive/receive_records_history_test.dart  # records partial/cancelled/completed
```

**Structure Decision**: Mobile feature-first. The drift database and `TransferHistoryRepository` live in **`core/`** because four features consume them and `core/` cannot import features (Constitution XI). `features/history/` owns only its UI + read use cases. The write path is a single core use case (`RecordTransferUseCase`) injected into the existing Send/Receive terminal-detection points — the lone additive edit to merged #004/#005 code, consistent with the additive-seam pattern of prior specs. `features/home/` consumes the same repository through its pre-built FR-008 swap seam. No feature imports another.

## Complexity Tracking

> No constitution violations — section intentionally empty.
