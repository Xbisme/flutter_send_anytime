# Phase 1 Data Model: Home Screen Completion (#012)

All types are **presentation/view-model** types derived from the persisted `TransferRecord`/`RecordedFile` (#006). No persisted schema changes. Source of truth = `TransferHistoryRepository`.

## Source entities (existing, #006 — read-only here)

- **`TransferRecord`**: `id`, `direction` (sent/received), `status` (completed/partial/failed/cancelled), `pairingMethod`, `fileCount`, `totalBytes`, `createdAt` (UTC), `peerLabel`, `files: List<RecordedFile>`. Helpers: `includedFiles` (files that landed), `isComplete`.
- **`RecordedFile`**: `name`, `size`, `mimeType?`, `path?` (received → final on-device path; sent → source path; may be null/stale), `included`, `ext` (derived upper-case extension).

## New / extended view-model types

### `MediaCategory` (enum) — NEW
`photos | videos | files`. The unit of the three StatTiles, the three Home media sections, and the See-all screens.

**Categorization rule (FR-012, deterministic, no I/O)** — `FileCategory.of(RecordedFile)`:
1. If `mimeType` is non-empty: `image/*` → `photos`; `video/*` → `videos`; else → `files`.
2. Else use lower-cased extension:
   - photos: `jpg jpeg png gif webp heic heif bmp tiff`
   - videos: `mp4 mov m4v 3gp avi mkv webm`
   - anything else → `files`.

### `TransferSummary` (hero) — EXISTING, now real
`sentBytes`, `receivedBytes`, `monthlyTransferCount`, `progressFraction`.
**Derivation** over all **counted records** (see counting rules):
- `sentBytes` = Σ `totalBytes` of sent records; `receivedBytes` = Σ of received records.
- `monthlyTransferCount` = count of counted records whose `createdAt.toLocal()` falls in the current local calendar month.
- `progressFraction` = `receivedBytes / (sentBytes + receivedBytes)`, or `0.0` when both are zero (FR-003; bounded 0..1).

### `StatTileModel` — EXISTING, now real
`kind: StatKind {photos,videos,files}`, `count`, `tint`. `count` = number of **counted files** in that category across all counted records.

### Recent media items — EXTENDED
The existing `MediaThumb` / `VideoThumb` / `FileItemModel` gain (additive):
- `category: MediaCategory`
- `record: TransferRecord` (backing record → tap target = its History detail)
- `localPath: String?` (the file's on-disk path when available + readable → drives the real thumbnail; null → icon fallback)
- existing: `name`, `sizeLabel` (mono, `Formatters.bytes`); `VideoThumb.durationLabel` (when known); `FileItemModel.ext`/`meta`.

> A single unified `MediaItem` view-model MAY back both Home cells and the See-all list to avoid three parallel shapes — decided at implementation; the fields above are the contract either way.

### `HomeDashboard` — EXISTING contract, now fully real
`summary`, `stats` (3 tiles), `recentImages` (≤ cap), `recentVideos` (≤ cap), `recentFiles` (≤ cap), `recentTransfers` (already real, #006). Built by `HomeDashboardBuilder.build(List<TransferRecord>)`.

### `MediaItem` collection (See-all) — NEW
The full ordered (`createdAt` desc, then stable) list of items of one `MediaCategory` — every counted file of that category across history, **not** capped. Backs `SeeAllCubit` / `SeeAllPage`.

## Counting & inclusion rules (FR-004/FR-012; Assumptions)

- **Counted records**: only **successfully transferred** outcomes count toward summary + stats + media. `completed` records count fully; `partial` records count only their `includedFiles`; `failed`/`cancelled` records are **excluded** entirely.
- **Both directions**: sent **and** received counted (everything that moved through the app).
- **Per-file granularity**: stat counts and media items are per **file** (a record with 3 photos contributes 3 to the photos count + up to the cap of photo items). The hero `monthlyTransferCount` is per **record** (a "transfer"), not per file.
- **Recency**: order by the record's `createdAt` (desc); files within a record keep manifest order.

## State / lifecycle

- No state machine. `HomeCubit` and `SeeAllCubit` are reactive 4-state cubits over history streams (`initial → loading → loaded(data) → error(failure)`); they re-`loaded` on each stream snapshot (FR-011).
- **Thumbnail availability** is resolved at render time: `localPath` non-null + file exists/readable → real thumbnail; otherwise type icon (FR-006a / FR-014). The open action's availability is handled by the existing History detail page (#006).

## Empty states (FR-010)

- No counted records → hero zeros, all stat tiles `0`, each media section + See-all shows its empty state. Distinct copy for "never transferred" (Home/See-all) — there is no filtered "no results" case here (Home is unfiltered).
