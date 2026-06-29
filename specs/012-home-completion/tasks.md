---
description: "Task list for #012 Home Screen Completion"
---

# Tasks: Home Screen Completion (#012)

**Input**: Design documents from `/specs/012-home-completion/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/](contracts/), [quickstart.md](quickstart.md)

**Tests**: INCLUDED — Constitution XII mandates unit + BLoC + widget tests for this UI/data feature. **No two-device smoke** (local, non-transfer feature — only a manual on-device UI pass, deferred banner below).

**Organization**: grouped by user story (P1 → P1 → P2) for independent implementation + testing.

> **Scope recap**: purely additive, feature-local rework of Home over the #006 history store. **No new packages, no engine/signaling/transport/protocol/DB-schema edits.** Data source = transfer history only (FR-016). Tap → existing History detail (#006). Toolchain: use `dart analyze lib test` (not `flutter analyze`).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no incomplete-task dependency)
- **[Story]**: US1 / US2 / US3 (setup, foundational, polish carry no story label)

---

## Phase 1: Setup

**Purpose**: design source + confirm no infra churn before code.

- [x] T001 DesignSync (R7): `/design-login`, pull the updated **Home** + new **See-all** screens from claude_design `SafeSend`; distil into [.claude/claude-app/ui-design-context.md](../../.claude/claude-app/ui-design-context.md) (§Screen 01 + a new See-all section). Confirm preview caps + the video-tile/thumbnail treatment against the render.
- [x] T002 Confirm **no dependency changes** (Constitution XV): feature uses only existing packages; `pubspec.yaml`/`pubspec.lock` MUST stay unchanged. Verify `TransferHistoryRepository.watch(HistoryFilter.none)` returns records **with file rows** (mime/path) — the data the builder needs.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: the pure data layer + reactive cubit every story renders from. **No user-story rendering starts until this completes.**

- [x] T003 [P] Create `MediaCategory` enum + pure `FileCategory.of(RecordedFile)` (MIME-then-extension, per [data-model.md](data-model.md)) in `lib/core/utils/file_category.dart`.
- [x] T004 [P] FileCategory unit test (acceptance matrix: image/video MIME, null-MIME extension fallback, unknown → files) in `test/core/utils/file_category_test.dart`.
- [x] T005 Extend Home view-models in `lib/features/home/domain/models/home_dashboard.dart`: media items (`MediaThumb`/`VideoThumb`/`FileItemModel`, or a unified `MediaItem`) gain `category` + `record: TransferRecord` + `localPath: String?` (additive); import `MediaCategory`.
- [x] T006 Implement pure `HomeDashboardBuilder.build(List<TransferRecord> records, {required DateTime now})` → `HomeDashboard` (summary sums, calendar-month count using the injected `now`, progress fraction, 3 stat counts, capped recent media per category, reuse existing recent-transfers mapping) in `lib/features/home/data/home_dashboard_builder.dart`, per [contracts/home-dashboard.md](contracts/home-dashboard.md) + [data-model.md](data-model.md) counting rules (completed full; partial → includedFiles; failed/cancelled excluded; both directions). **`now` is injected (not `DateTime.now()` inline) for deterministic tests (analyze U1).**
- [x] T007 [P] HomeDashboardBuilder unit test (byte sums per direction, monthly-count boundary, per-file stat counts, categorization, recency order, partial/failed exclusion, empty → zeros) in `test/features/home/home_dashboard_builder_test.dart`.
- [x] T008 Implement `WatchHomeDashboardUseCase` (`Stream<HomeDashboard> call()` over `watch(HistoryFilter.none)` → builder) in `lib/features/home/domain/usecases/watch_home_dashboard_usecase.dart` (`@injectable`).
- [x] T009 Rework `HomeCubit` to be **reactive** (subscribe to `WatchHomeDashboardUseCase`, `emitLoaded` per snapshot, `emitError` on stream error, cancel subscription in `close()`); remove `HomePlaceholderDataSource` usage in `lib/features/home/presentation/cubit/home_cubit.dart`; delete `lib/features/home/data/home_placeholder_data_source.dart`; update DI registrations.
- [x] T010 [P] HomeCubit bloc_test (initial→loading→loaded on first snapshot; re-`loaded` on a new history snapshot = live update FR-011; empty history → zeroed dashboard; stream error → error) in `test/features/home/home_cubit_test.dart`.
- [x] T011 [P] Add base ARB strings (VI primary + EN, `@description`, key parity) in `lib/l10n/arb/`: stat-tile labels (if missing), per-section empty-state copy, and the file-unavailable message. (`homeSeeAll` label already exists.)

**Checkpoint**: real dashboard streams into `HomeCubit`; data layer fully unit-tested. Stories can render.

---

## Phase 3: User Story 1 — Home reflects my real transfer activity (Priority: P1) 🎯 MVP

**Goal**: hero card + 3 StatTiles show real aggregates from history; zeros + no mock on fresh install.

**Independent Test**: with mixed transfers, hero totals + monthly count + stat counts match history; fresh install shows zeros, no placeholder.

- [x] T012 [US1] Render the hero card from the real `TransferSummary` (sent/received via mono `Formatters.bytes`, monthly count, progress bar from `progressFraction`; zeros on empty) in `lib/features/home/presentation/widgets/home_sections.dart`.
- [x] T013 [US1] Render the 3 StatTiles from real counts (reuse `StatTile`, mono tabular figures) in `lib/features/home/presentation/widgets/home_sections.dart`.
- [x] T014 [P] [US1] Widget test: hero + stat tiles show real values for a seeded history and zeroed/empty state for empty history (SC-001/SC-002) in `test/features/home/home_page_test.dart`.

**Checkpoint**: Home numbers are real — demoable MVP.

---

## Phase 4: User Story 2 — Recent media is my real transferred content (Priority: P1)

**Goal**: Ảnh/Video/File gần đây show real recent items (newest-first) with real thumbnails when the file is local; tap → History detail; empty states replace placeholders.

**Independent Test**: recent sections list real items per category with name/size (+ video duration); received images show real thumbnails, sent/missing show type icons; empty category shows empty state; tap routes to detail.

- [x] T015 [US2] Create shared `MediaThumbnail` widget (image → `Image.file` with `cacheWidth` at cell size + error/loading fallback to type icon; video → token tile with play glyph + duration; unavailable → type icon) in `lib/core/presentation/media/media_thumbnail.dart` (imports no features; tokens only).
- [x] T016 [P] [US2] MediaThumbnail widget test (existing image path → renders `Image.file`; null/missing path → type icon; video → play glyph + duration label) in `test/core/presentation/media_thumbnail_test.dart`.
- [x] T017 [US2] Create the shared media cell + wire `recentImages` (3-col grid), `recentVideos` (2-col grid), `recentFiles` (`FileRow` list) into `home_sections.dart` using `MediaThumbnail`; per-section empty states (FR-010) in `lib/features/home/presentation/widgets/media_grid_item.dart` + `home_sections.dart`.
- [x] T018 [US2] Wire interactions in `lib/features/home/presentation/home_page.dart` / `home_sections.dart`: item tap → `context.push(AppRoutes.historyDetail, extra: item.record)` (FR-007); each section's "Xem tất cả" → `context.push(AppRoutes.homeSeeAll, extra: category)` (FR-008; route lands in US3).
- [x] T019 [P] [US2] Widget test: real media items render newest-first with name+size (+ video duration), empty section shows empty state, item tap navigates to `historyDetail` in `test/features/home/home_page_test.dart`.

**Checkpoint**: Home is fully real (US1 + US2). Independently testable.

---

## Phase 5: User Story 3 — See all of a category (Priority: P2)

**Goal**: each section's "Xem tất cả" opens a dedicated full-screen list of all items of that category; own route + back; empty state; tap → detail.

**Independent Test**: tap "Xem tất cả" on each section → full list (beyond the Home cap), scrolls a large set smoothly, back returns to Home, tap routes to detail, empty category shows empty state.

- [x] T020 [US3] Add `AppRoutes.homeSeeAll` constant in `lib/core/constants/app_routes.dart` + register its `GoRoute` on the root navigator key (hides bottom nav) building `SeeAllPage(category: state.extra! as MediaCategory)` in `lib/core/router/app_router.dart`.
- [x] T021 [US3] Implement `WatchMediaItemsUseCase` (`Stream<List<MediaItem>> call(MediaCategory)` over the full history stream → all counted items of that category, no cap) in `lib/features/home/domain/usecases/watch_media_items_usecase.dart` (`@injectable`).
- [x] T022 [US3] Implement `SeeAllCubit` (`@injectable`, 4-state, `load(category)` subscribes, `emitLoaded` per snapshot, cancel on close) in `lib/features/home/presentation/cubit/see_all_cubit.dart`.
- [x] T023 [P] [US3] SeeAllCubit bloc_test (load → loaded list; live update; empty → empty list; error) in `test/features/home/see_all_cubit_test.dart`.
- [x] T024 [US3] Implement `SeeAllPage` (flow `AppBar` localized per-category title; lazy `GridView.builder` for photos/videos, `ListView.builder` for files reusing the US2 cell; empty state; item tap → `historyDetail`) in `lib/features/home/presentation/see_all/see_all_page.dart`.
- [x] T025 [P] [US3] Add See-all ARB titles (VI primary + EN, `@description`): "Tất cả ảnh / video / tệp" in `lib/l10n/arb/`.
- [x] T026 [P] [US3] Widget test: SeeAllPage renders the full category list, empty state for an empty category, and item tap routes to `historyDetail` in `test/features/home/see_all_page_test.dart`.

**Checkpoint**: all three stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T027 [P] FR-014: confirm opening an item whose underlying file is unavailable surfaces a graceful localized message (reuses the #006 detail Open path) — no crash; add/extend a test if the existing #006 coverage doesn't assert it.
- [x] T028 [P] Accessibility: semantic labels on media cells (name + category + size) + ensure dark-mode/token compliance of the new `MediaThumbnail`/cells/See-all (no hardcoded hex, mono tabular figures for sizes/counts).
- [x] T029 Run CI gates green: `dart analyze lib test` = 0 · `flutter test` all pass · `dart format --set-exit-if-changed .` clean (+ bloc lint when the CLI is available).
- [x] T030 [P] Docs at merge: append [changelog.md](../../.claude/claude-app/changelog.md) + flip status in [project-context.md](../../.claude/claude-app/project-context.md) + [sdd-roadmap.md](../../.claude/claude-app/sdd-roadmap.md); confirm [ui-design-context.md](../../.claude/claude-app/ui-design-context.md) §Screen 01 + See-all is accurate.
- [ ] T031 **[DEFERRED · device]** Manual quickstart pass on simulator/device per [quickstart.md](quickstart.md): fresh-install empty states, real aggregates/media, live update after a transfer, received-image thumbnails vs icons, See-all large-list smooth scroll + back. (No two-device smoke — local feature.)

---

## Dependencies & Execution Order

- **Setup (T001–T002)** → no code deps; T001 (DesignSync) gates final UI polish, not the data layer.
- **Foundational (T003–T011)** → blocks all stories. T003→T004; T005 before T006; T006→T007; T006→T008→T009→T010; T011 parallel.
- **US1 (T012–T014)** → after Foundational. T012/T013 same file (sequential); T014 after.
- **US2 (T015–T019)** → after Foundational (independent of US1). T015→T016; T017 after T015; T018 after T017; T019 after T018. ("Xem tất cả" tap target route lands in US3 — wire the push in T018; it resolves once T020 exists.)
- **US3 (T020–T026)** → after Foundational (needs the US2 cell for reuse). T020/T021 parallel; T022 after T021; T023 after T022; T024 after T020+T022; T025/T026 parallel after T024.
- **Polish (T027–T031)** → after the desired stories; T031 deferred (manual).

### Within each story

Tests written alongside → data/use case → cubit → widget → route. Commit after each task or logical group.

---

## Implementation Strategy

### MVP First (US1)

1. Phase 1 Setup → 2. Phase 2 Foundational (blocks all) → 3. Phase 3 US1 → **STOP & VALIDATE**: Home hero + stats are real, zeros on fresh install → demo MVP.

### Incremental Delivery

US1 (real numbers) → US2 (real recent media + thumbnails + tap) → US3 (See-all). Each adds value without breaking the prior; DesignSync (T001) lands before final UI polish.

---

## Notes

- [P] = different files, no incomplete-task dependency.
- No engine/signaling/transport/protocol/DB-schema edits — additive read paths + new See-all screen only (mirrors #006/#008/#010).
- Single data source = the #006 transfer-history store (FR-015/FR-016); no parallel/duplicate store, no on-device media library, no new permission.
- No file path / peer identifier logged (Principle I). Thumbnails decoded at cell size (bounded memory, Principle II).
