# Implementation Plan: Home Screen Completion

**Branch**: `012-home-completion` | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/012-home-completion/spec.md`

## Summary

Replace the remaining placeholder content on the Trang chủ (Home) screen — the hero summary card, the three StatTiles (Ảnh / Video / File), and the Recent photos / videos / files sections — with **real data derived from the transfer history** (#006), and add a "Xem tất cả" (See all) destination screen per media category. Recent items are sourced **exclusively from transfer history** (no on-device media library, no new permission — FR-016). Tapping any item navigates to the existing History detail page (#006). Image/video grid cells show a **real decoded thumbnail when the file is available locally** (received, on-disk), falling back to a file-type icon otherwise.

Technical approach: purely additive, feature-local work in `features/home/` over the existing core `TransferHistoryRepository`. The `HomeCubit` becomes **reactive** (subscribes to the history stream so the dashboard updates live, FR-011) and builds the full `HomeDashboard` from real records via new Home use cases + pure mappers, removing the `HomePlaceholderDataSource`. The `HomeDashboard` view-model is extended additively (category + open-reference + local thumbnail path on the media items). A new `AppRoutes.homeSeeAll` route + a screen-scoped `SeeAllCubit` back the See-all screens, reusing the same item widgets and tap-to-detail behavior as Home. **No new packages, no engine/signaling/transport/protocol/DB-schema changes.**

## Technical Context

**Language/Version**: Dart 3.11.x / Flutter 3.41 (project floor; per existing pubspec)
**Primary Dependencies**: `flutter_bloc` (4-state Cubit), `get_it` + `injectable` (DI), `go_router` (routing), `drift` via the existing `TransferHistoryRepository` (read-only here), `intl` via `Formatters`. **No new packages.**
**Storage**: Existing drift history store (#006), read-only — `TransferHistoryRepository.watch(HistoryFilter.none)` / `watchRecent(limit)`. No schema change.
**Testing**: `flutter_test` + `bloc_test` + `mocktail`; in-memory fakes of `TransferHistoryRepository`; widget tests for Home sections + See-all; `dart analyze lib test` = 0 (toolchain note: `flutter analyze` crashes on this checkout — use `dart analyze`).
**Target Platform**: iOS 13.0+ / Android 8.0 (API 26)+ (phones; responsive).
**Project Type**: Mobile app (Flutter), Clean Architecture + feature-first.
**Performance Goals**: Home renders from a cached stream snapshot without jank; thumbnails decoded at cell size (`cacheWidth`/`cacheHeight`) so a grid never holds full-resolution bitmaps; See-all lists render lazily (`GridView/ListView.builder`).
**Constraints**: Streamed/bounded-memory image decode (Principle II); metadata-only history (Principle I/II) — no file contents read except a bounded thumbnail decode of an already-saved file; VI-primary i18n; fixed design tokens.
**Scale/Scope**: 1 reworked screen (Home), 3 See-all screen variants (one parametrized screen), ~hundreds of history records typical; See-all must scroll large sets smoothly (SC-006).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ | Read-only over metadata-only history; thumbnails decode an already-saved local file the user received. No paths/identifiers logged. |
| II. Direct Transfer & Data Minimization | ✅ | No new persistence; thumbnails decoded at bounded size (`cacheWidth`) — no full media in memory; no content telemetry. |
| III. BLoC-Driven State | ✅ | `HomeCubit` stays 4-state (becomes stream-reactive, emits `loaded` per snapshot); new `SeeAllCubit` 4-state `@injectable`, page-scoped. Use cases injected (not repo). |
| IV. Code Quality & Dart Safety | ✅ | `very_good_analysis` 0; explicit types; immutable view-models. |
| V. Result<T> Error Handling | ✅ | Use cases expose streams; one-shot reads fold `Result`; cubit `emitError` on failure. No try/catch in cubit. |
| VI. Design System & Theming | ✅ | Reuse `StatTile`, `FileRow`, section widgets, tokens; new `MediaThumbnail` widget in `core/presentation/` (shared, token-styled). No hardcoded hex. Mono tabular figures for sizes/counts. |
| VII. Cross-Platform Native | ✅ | No new native integration/permission. Responsive grids; a11y labels on items; Reduce-Motion N/A (no new animation). |
| VIII. Transport & Signaling | ✅ | Untouched — no engine/signaling/transport/protocol edits. |
| IX. Transfer Reliability & Integrity | ✅ | No transfer-path changes; no DB migration (read-only). |
| X. go_router Navigation | ✅ | New `AppRoutes.homeSeeAll` constant; `context.push` with a core-typed extra; tap → `AppRoutes.historyDetail` with the `TransferRecord`. |
| XI. Feature-First Modularity | ✅ | All new code in `features/home/`; consumes core history via use cases. `core/` gains only a shared `MediaThumbnail` widget + (optionally) a pure `FileCategory` helper — imports no features. |
| XII. Testing Discipline | ✅ | BLoC tests for `HomeCubit`/`SeeAllCubit`; unit tests for categorization + mappers; widget tests for sections + See-all + empty states. No two-device smoke (local, non-transfer feature). |
| XIII. Simplicity & YAGNI | ✅ | Zero new packages; reuse `HistoryFilter.none` instead of new aggregate queries; one parametrized See-all screen, not three. |
| XIV. i18n by Default | ✅ | New ARB strings (stat labels, section titles, See-all titles, empty-state copy, file-unavailable) VI primary + EN with `@description`; locale-aware `Formatters`. |
| XV. Dependency Hygiene | ✅ | No dependency changes. (Video frame extraction would need a native plugin → explicitly rejected in research; see R3.) |

**Result**: PASS (no violations; Complexity Tracking not required).

## Project Structure

### Documentation (this feature)

```text
specs/012-home-completion/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (UI + use-case contracts)
│   ├── home-dashboard.md
│   └── see-all-screen.md
├── checklists/
│   └── requirements.md  # from /speckit.specify
└── tasks.md             # /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   └── app_routes.dart                  # + homeSeeAll constant
│   ├── presentation/
│   │   └── media/
│   │       └── media_thumbnail.dart         # NEW shared widget: local thumbnail | type-icon fallback
│   ├── router/
│   │   └── app_router.dart                   # + homeSeeAll GoRoute (rootKey, hides nav)
│   └── utils/
│       └── file_category.dart                # NEW pure helper: mime/ext → MediaCategory
└── features/home/
    ├── domain/
    │   ├── models/
    │   │   ├── home_dashboard.dart           # EXTEND: MediaThumb/VideoThumb/FileItemModel gain category + record ref + localPath; MediaCategory enum
    │   │   └── media_item.dart               # NEW (optional): unified recent-media view-model for See-all
    │   └── usecases/
    │       ├── watch_recent_transfers_usecase.dart   # existing
    │       ├── watch_home_dashboard_usecase.dart     # NEW: history stream → HomeDashboard (summary+stats+media+recent)
    │       └── watch_media_items_usecase.dart        # NEW: history stream → all items of one MediaCategory (See-all)
    ├── data/
    │   ├── home_history_data_source.dart      # existing mapper (recent transfers) — extend/replace
    │   ├── home_dashboard_builder.dart        # NEW pure builder: List<TransferRecord> → HomeDashboard
    │   └── home_placeholder_data_source.dart  # REMOVE (no longer used)
    └── presentation/
        ├── cubit/
        │   ├── home_cubit.dart                # REWORK: subscribe to dashboard stream (reactive)
        │   └── see_all_cubit.dart             # NEW @injectable 4-state, watches one category
        ├── home_page.dart                     # wire See-all taps + item taps → historyDetail
        ├── widgets/
        │   ├── home_sections.dart             # render real media + thumbnails + See-all affordance
        │   └── media_grid_item.dart           # NEW: shared item cell (uses MediaThumbnail)
        └── see_all/
            └── see_all_page.dart              # NEW parametrized full-screen list per category

test/
├── core/utils/file_category_test.dart                         # NEW
├── features/home/home_dashboard_builder_test.dart             # NEW (summary/stats/categorization/recency)
├── features/home/home_cubit_test.dart                         # REWORK (reactive load + live update + empty)
├── features/home/see_all_cubit_test.dart                      # NEW
└── features/home/home_page_test.dart / see_all_page_test.dart # widget: real data, empty states, taps
```

**Structure Decision**: Feature-first (Constitution XI). All business logic lives in `features/home/`; the only `core/` additions are a pure `FileCategory` helper and a shared `MediaThumbnail` widget (both feature-agnostic, import no features). The Home feature reads the cross-feature history store through the existing core `TransferHistoryRepository` via new use cases — never importing another feature.

## Phase 0 — Research

See [research.md](research.md). Key decisions:

- **R1 — Aggregate source**: reuse `TransferHistoryRepository.watch(HistoryFilter.none)` (full newest-first stream, already loads file rows) and derive summary/stats/recent-media in a pure Dart builder. Rejected: adding drift `COUNT/SUM` aggregate queries (premature optimization for metadata-only data — Constitution XIII); revisit only if profiling shows a problem.
- **R2 — Reactive Home**: switch `HomeCubit` from a one-shot `.first` read to a `StreamSubscription`, emitting `loaded` on each snapshot (FR-011). Cancel on `close()`.
- **R3 — Thumbnails**: images → `Image.file` with `cacheWidth` at cell size (bounded memory, no new dep). Videos → file-type/play tile (duration label) on a token background; **real video-frame extraction is rejected for #012** (would require a native plugin, e.g. `video_thumbnail` — Constitution XV/XIII; in-app media rendering is #013). FR-006a "real thumbnail when available" is satisfied for images on-disk; video shows its design tile.
- **R4 — Categorization**: deterministic by MIME type when present, else by file extension; image/* → Ảnh, video/* → Video, else File (FR-012).
- **R5 — See-all scope**: one parametrized screen (`MediaCategory` via route extra) listing ALL items of that category (no preview cap), lazy-built; Home preview capped at a small N (R6).
- **R6 — Preview caps & "this month"**: Home media previews capped (proposed: photos 6, videos 4, files 4 — confirm against DesignSync render); monthly count = local calendar month of `createdAt` (FR-002).
- **R7 — DesignSync**: pull the updated Home + new See-all screens from claude_design `SafeSend` and distil into `ui-design-context.md` before building UI (tasks-phase gate; existing Screen 01 description is the interim source).

## Phase 1 — Design & Contracts

- [data-model.md](data-model.md): `MediaCategory` enum; categorization rules + MIME/extension tables; extended `HomeDashboard` view-models (media items gain `category`, `record`, `localPath`); `MediaItem` (See-all) view-model; `TransferSummary` derivation rules; counting rules (successful/included files only, both directions).
- [contracts/home-dashboard.md](contracts/home-dashboard.md): the `WatchHomeDashboardUseCase` stream contract + builder mapping rules + Home rendering/empty-state contract.
- [contracts/see-all-screen.md](contracts/see-all-screen.md): route contract (`AppRoutes.homeSeeAll` + `MediaCategory` extra), `SeeAllCubit` states, list rendering, tap → `historyDetail`, empty state.
- [quickstart.md](quickstart.md): build order, manual verification, DesignSync step, gates.
- Agent context: update the `<!-- SPECKIT -->` block in `CLAUDE.md` to point at this plan.

**Post-Design Constitution re-check**: PASS — design adds no packages, no schema/transport edits, keeps all logic feature-local, preserves 4-state BLoC + Result + tokens + i18n.
