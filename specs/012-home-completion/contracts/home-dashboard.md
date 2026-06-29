# Contract: Home Dashboard (real data)

UI + use-case contract for the reworked Trang chủ (Home) screen. Backed by the existing core `TransferHistoryRepository` (read-only).

## Use cases (feature/home/domain/usecases)

### `WatchHomeDashboardUseCase`
- **Signature**: `Stream<HomeDashboard> call()`
- **Behavior**: subscribes to `TransferHistoryRepository.watch(HistoryFilter.none)`; maps each `List<TransferRecord>` snapshot through `HomeDashboardBuilder.build(records)` to a fully real `HomeDashboard`. Emits on every history change (FR-011).
- **Errors**: stream errors propagate → `HomeCubit.emitError(AppFailure)`.

### `WatchMediaItemsUseCase`
- **Signature**: `Stream<List<MediaItem>> call(MediaCategory category)`
- **Behavior**: subscribes to the same full history stream; flattens counted files of `category` (per counting rules) into recency-ordered `MediaItem`s — **no cap**. Backs the See-all screen.

> Both use cases are `@injectable`, injected into cubits (Constitution III — use cases, not the repo).

## Builder (pure)

### `HomeDashboardBuilder.build(List<TransferRecord> records) → HomeDashboard`
- Filters to **counted records** (completed fully; partial → `includedFiles`; failed/cancelled excluded).
- Computes `TransferSummary` (sent/received byte sums, calendar-month record count, progress fraction) per data-model rules.
- Computes the 3 `StatTileModel` counts (per-file, per category).
- Builds `recentImages`/`recentVideos`/`recentFiles` capped at the section caps (R6), each item carrying `category` + `record` + `localPath`.
- Reuses the existing real `recentTransfers` mapping (#006).
- Pure + deterministic → directly unit-testable.

## HomeCubit contract (4-state, reactive)
- `load()` → `emitLoading()`, then subscribe to `WatchHomeDashboardUseCase()`:
  - each snapshot → `emitLoaded(dashboard)`
  - stream error → `emitError(failure)`
- `close()` cancels the subscription.
- No try/catch in the cubit (Constitution V).

## Rendering contract (home_page / home_sections)
- **Hero**: real sent/received (mono, tabular `Formatters.bytes`), monthly count, progress bar from `progressFraction`. Zeros on empty (FR-010).
- **Stat tiles**: reuse `StatTile` with real counts (mono figures).
- **Media sections**: render up to the cap; each cell uses the shared `MediaThumbnail` (real `Image.file` when `localPath` available, else type icon — FR-006a). Photos = 3-col grid, Videos = 2-col grid (play + duration), Files = `FileRow` list.
- **Empty section** → localized empty state instead of placeholder tiles (FR-010).
- **"Xem tất cả"** affordance per section → `context.push(AppRoutes.homeSeeAll, extra: category)` (FR-008).
- **Item tap** → `context.push(AppRoutes.historyDetail, extra: item.record)` (FR-007; reuses #006 detail's Open/Share).
- **Accessibility**: each item exposes a semantic label (name + category + size).

## Invariants
- No placeholder/mock values anywhere once history is loaded (SC-001).
- No new persistence or DB query types; no engine/transport edits.
- No file path / peer identifier logged (Principle I).
