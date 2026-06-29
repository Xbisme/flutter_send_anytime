# Phase 0 Research: Home Screen Completion (#012)

All decisions resolve the Technical Context unknowns for a purely additive, feature-local rework of Home over the existing #006 history store. No new packages.

## R1 — Aggregate / recent-media data source

- **Decision**: Reuse the existing core `TransferHistoryRepository`. Subscribe to `watch(HistoryFilter.none)` for the **full** newest-first record stream (used for hero summary, stat counts, and per-category media), and keep `watchRecent(limit)` available for the recent-transfers strip. Derive everything in a **pure Dart builder** (`HomeDashboardBuilder`) and pure mappers.
- **Rationale**: The repo already returns `TransferRecord`s **with their file rows** (the existing `HomeHistoryMapper` reads `r.files.first.name`/`r.fileCount`), so MIME/size/path per file are available for categorization and thumbnails. History is **metadata-only and small**; computing sums/counts in Dart is trivial and avoids new DB code (Constitution XIII) and any schema change (FR-015). `HistoryFilter.none` already exists as the unfiltered view.
- **Alternatives considered**:
  - Add drift `COUNT(*)`/`SUM(bytes)`/per-category aggregate queries to the repository — rejected as premature optimization for metadata-scale data; revisit only if profiling shows a real cost.
  - A separate "media index" table — rejected (duplicate store, FR-015 forbids).

## R2 — Reactive Home (live updates, FR-011)

- **Decision**: Change `HomeCubit` from a one-shot `await stream.first` to a **`StreamSubscription`** over `WatchHomeDashboardUseCase()`; emit `loaded(dashboard)` on every snapshot, `error` on stream error; cancel the subscription in `close()`.
- **Rationale**: FR-011 requires Home to reflect new/deleted transfers without a restart. drift streams already emit on every write (Send/Receive record, History delete/clear), so a subscription gives live updates for free. Stays within the 4-state pattern (Principle III).
- **Alternatives**: re-fetch on `didChangeDependencies`/route focus — rejected (misses background completions, more code, less reactive).

## R3 — Thumbnails (FR-006 / FR-006a)

- **Decision**:
  - **Images**: when the item's `RecordedFile.path` exists and is readable, render `Image.file(File(path), cacheWidth: <cellPx>)` (decode bounded to the cell), with an error/loading fallback to the type icon.
  - **Videos**: render the design's video tile — a token-background cell with a play glyph + duration label (duration shown when known). **Real video-frame extraction is out of scope for #012.**
  - **Unavailable / sent-only / unreadable**: file-type icon (Lucide) on a token-background tile.
- **Rationale**: Images give a real preview with **zero new dependencies** and bounded memory (`cacheWidth` honors Principle II's streamed/bounded-I/O intent). A real video frame would require a **native plugin** (e.g. `video_thumbnail`) — rejected under Constitution XV (native-heavy, new min-OS/permission surface) and XIII (YAGNI); rich in-app media rendering is the explicit scope of **#013 In-App Viewers**. This still satisfies the clarification ("real thumbnail when the file is available") for images, the dominant photo grid, while keeping #012 dependency-free.
- **Alternatives**: add `video_thumbnail` now — rejected (defer to #013); always-placeholder images — rejected (fails FR-006a + the "real data" goal).

## R4 — File categorization (FR-012)

- **Decision**: A pure `FileCategory`/`MediaCategory` helper. Classify by **MIME type when present** (`image/*` → photos, `video/*` → videos, else files); when MIME is null/empty, fall back to the **file extension** against fixed lists; anything not image/video → **File**. Deterministic, no I/O.
- **Rationale**: `RecordedFile.mimeType` is often present (set on send/receive); extension is a reliable fallback (`RecordedFile.ext` already exists). Matches FR-012's "deterministic and documented".
- **Extension lists** (initial, lowercase; documented in data-model): images `jpg jpeg png gif webp heic heif bmp tiff`; videos `mp4 mov m4v 3gp avi mkv webm`.

## R5 — See-all screen shape (FR-008/FR-009)

- **Decision**: **One** parametrized full-screen route `AppRoutes.homeSeeAll` taking a `MediaCategory` via `go_router` `extra`; a page-scoped `SeeAllCubit` watches `WatchMediaItemsUseCase(category)` (no preview cap). Photos/videos render as a grid, files as a list, reusing the same item cells as Home. Pushed on the root navigator (hides bottom nav, consistent with flow routes).
- **Rationale**: One screen, three behaviors keyed by category (Constitution XIII) vs three near-duplicate screens. Same item widgets ⇒ identical metadata + tap behavior as Home (FR-009).
- **Alternatives**: three separate routes/pages — rejected (duplication).

## R6 — Preview caps & "this month"

- **Decision**: Home media previews capped at a small fixed N per section (proposed **photos 6 / videos 4 / files 4** — final values confirmed against the DesignSync render). "Transfers this month" = count of records whose `createdAt` is within the **current local calendar month**. Hero progress fraction = received ÷ (sent + received) bytes (0 when both zero).
- **Rationale**: Caps keep Home light; See-all is the path to the full set (FR-013). Calendar-month matches the spec assumption; the progress fraction gives FR-003 a real, bounded value.

## R7 — Design source (DesignSync)

- **Decision**: Before building UI, pull the updated **Home** and the new **See-all** screens from the claude_design `SafeSend` project via `DesignSync` and distil them into `.claude/claude-app/ui-design-context.md` (§Screen 01 + a new See-all section). Until then, the existing §Screen 01 description (hero gradient card, 3 StatTiles, Ảnh 3-col / Video 2-col / File list, recent-transfers strip, quick-actions) is the interim source.
- **Rationale**: UI source-of-truth discipline (Constitution VI). DesignSync needs auth (`/design-login`) and is a manual step — captured as the first tasks-phase item, not a code dependency. The data/logic layer (builder, use cases, cubits, categorization, thumbnails) can be built and tested before the final visual polish.

## Summary of decisions

| # | Decision | New dep? |
|---|---|---|
| R1 | Reuse `watch(HistoryFilter.none)` + pure builder | No |
| R2 | Reactive `HomeCubit` via `StreamSubscription` | No |
| R3 | Real `Image.file` thumbnails (images); design tile for video | No |
| R4 | MIME-then-extension categorization helper | No |
| R5 | One parametrized See-all screen | No |
| R6 | Preview caps + calendar-month count | No |
| R7 | DesignSync before UI polish | No |

No `NEEDS CLARIFICATION` remain. No package additions ⇒ no `pubspec.lock`/`Podfile.lock` churn (Constitution XV).
