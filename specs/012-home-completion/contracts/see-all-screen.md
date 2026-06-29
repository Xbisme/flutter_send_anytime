# Contract: See-all Screen (Xem tất cả)

A single parametrized full-screen destination listing every transferred item of one `MediaCategory`.

## Route
- **Constant**: `AppRoutes.homeSeeAll` (NEW) — e.g. `/home/see-all`.
- **Registration**: `GoRoute` on the **root navigator key** (hides the bottom nav, consistent with other pushed flow screens — Constitution X / Principle VI IA).
- **Argument**: `MediaCategory` passed via `go_router` `extra` (core-typed; no feature import). Builder: `(_, state) => SeeAllPage(category: state.extra! as MediaCategory)`.
- **Entry**: from each Home media section's "Xem tất cả" affordance via `context.push`.

## SeeAllCubit (4-state, `@injectable`, page-scoped)
- `load(MediaCategory category)` → `emitLoading()`, subscribe to `WatchMediaItemsUseCase(category)`:
  - each snapshot → `emitLoaded(List<MediaItem>)`
  - error → `emitError(failure)`
- `close()` cancels the subscription. No try/catch (Constitution V).

## Rendering contract (see_all_page)
- Flow `AppBar` with a localized per-category title ("Tất cả ảnh" / "Tất cả video" / "Tất cả tệp").
- **Lazy** layout (`GridView.builder` for photos/videos, `ListView.builder` for files) over the full list — never builds all cells at once (SC-006).
- Reuses the **same item cells** as Home (`MediaThumbnail` + metadata) → identical look + behavior (FR-009).
- **Item tap** → `context.push(AppRoutes.historyDetail, extra: item.record)` (FR-007).
- **Empty** (category has no items) → localized empty state (FR-010).
- Back navigation returns to Home with its (stream-backed) state intact (FR-009 / SC-004).

## Invariants
- Lists ALL items of the category (no preview cap) — the preview cap applies only to Home (FR-013).
- Same data source + categorization as Home (single source of truth).
- Thumbnails decoded at cell size (bounded memory, Principle II).
