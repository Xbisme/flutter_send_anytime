# Feature Specification: Home Screen Completion

**Feature Branch**: `012-home-completion`
**Created**: 2026-06-29
**Status**: Draft
**Input**: User description: "#012 Home Screen Completion — Replace the remaining hardcoded/mock content on the Trang chủ (Home) screen with real data, and build the 'Xem tất cả / See all' destination screens."

## Clarifications

### Session 2026-06-29

- Q: Data source for the recent media grids and stat counts? → A: Transfer history only — no on-device media library, no new permission (FR-016).
- Q: Where does tapping a recent/See-all media item go, given the in-app viewers (#013) are not built yet? → A: Navigate to the existing History detail page (#006) for that item's transfer record, which already provides per-file Open / Share (FR-007).
- Q: Do the Recent photos/videos grids show real thumbnails or placeholders? → A: Show a real image/video thumbnail when the item's file is available locally (received, on-disk); fall back to a file-type icon on a token background otherwise (FR-006a).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Home reflects my real transfer activity (Priority: P1)

As a returning user, when I open the Trang chủ (Home) screen I see my **actual** transfer history reflected in the hero card and the stat tiles — how much I have sent and received, how many transfers I made this month, and how many photos / videos / files I have moved through the app — instead of placeholder numbers.

**Why this priority**: This is the core of the feature. The Home screen is the app's landing surface; showing fabricated numbers undermines trust and makes the dashboard meaningless. Replacing the hero summary + stat tiles with real aggregates delivers immediate, standalone value and is testable on its own.

**Independent Test**: Complete a few transfers (some sent, some received, mixed file types), open Home, and confirm the hero totals (sent bytes / received bytes / transfers-this-month) and the three stat-tile counts (photos / videos / files) match the underlying transfer history. On a fresh install with no history, confirm the dashboard shows zeroed/empty states rather than mock numbers.

**Acceptance Scenarios**:

1. **Given** I have completed transfers in both directions, **When** I open Home, **Then** the hero card shows my real total bytes sent and received and the real count of transfers made in the current month.
2. **Given** I have transferred a mix of images, videos, and other files, **When** I open Home, **Then** each stat tile (Ảnh / Video / File) shows the real count of items of that category.
3. **Given** a brand-new install with no transfer history, **When** I open Home, **Then** the hero totals read zero and the stat tiles read zero, with no placeholder/mock values shown.
4. **Given** a new transfer completes while I am on another screen, **When** I return to Home, **Then** the hero and stat figures reflect the new transfer without requiring an app restart.

---

### User Story 2 - Recent media on Home is my real transferred content (Priority: P1)

As a user, the "Ảnh gần đây" (Recent photos), "Video gần đây" (Recent videos), and "File gần đây" (Recent files) sections on Home show the **real items I have recently transferred** (sent or received), newest first — not placeholder tiles. Tapping an item takes me to its detail / open action.

**Why this priority**: Alongside the hero/stats, the recent-media grids are the most visually prominent mock content. Real recent items make Home a useful jumping-off point to recently moved files. Equal priority to US1 because together they constitute "Home shows real data".

**Independent Test**: Transfer several files of each category, open Home, and confirm each section lists the real recent items of that type in recency order with correct name + size (and duration for video where available); confirm an empty category shows its empty state; confirm tapping an item routes to the corresponding detail/open action.

**Acceptance Scenarios**:

1. **Given** I recently transferred images, **When** I open Home, **Then** the Recent photos grid shows those images newest-first with their real name and size.
2. **Given** I recently transferred videos, **When** I open Home, **Then** the Recent videos grid shows those videos with name, size, and a duration label where the duration is known.
3. **Given** I recently transferred non-media files, **When** I open Home, **Then** the Recent files list shows those files with name, type, and metadata.
4. **Given** a category has no transferred items, **When** I open Home, **Then** that section shows a clear empty state instead of placeholder tiles.
5. **Given** a recent item is shown, **When** I tap it, **Then** I am taken to the item's detail / open action (consistent with how the same item opens elsewhere in the app).

---

### User Story 3 - See all of a category (Priority: P2)

As a user, each Home media section has a "Xem tất cả" (See all) affordance that opens a dedicated full-screen list of **all** items in that category (all recent photos, all recent videos, all recent files), so I am not limited to the few shown on Home.

**Why this priority**: The Home sections are previews; users need a way to browse the complete set. Valuable but secondary to having real data on Home itself — Home is usable without the See-all screens, so this is P2.

**Independent Test**: From a populated Home, tap "Xem tất cả" on each section and confirm a dedicated screen opens listing every item of that category (beyond the Home preview), with the same item metadata and tap-to-open behavior, its own route/back navigation, and an empty state when the category is empty.

**Acceptance Scenarios**:

1. **Given** I am on Home with more items than the preview shows, **When** I tap "Xem tất cả" on a section, **Then** a full-screen list opens showing all items of that category.
2. **Given** I am on a See-all screen, **When** I tap an item, **Then** it opens the same detail/open action as from Home.
3. **Given** I am on a See-all screen, **When** I navigate back, **Then** I return to Home with its state preserved.
4. **Given** a category is empty, **When** I open its See-all screen, **Then** I see a clear empty state.

---

### Edge Cases

- **Fresh install / no history**: hero totals and stat counts read zero; media sections and See-all screens show empty states; no mock content anywhere.
- **A transferred file no longer exists on disk** (deleted/moved after transfer): the item may still be counted/listed from the record, but its open action surfaces a graceful "file unavailable" message rather than crashing. (Counts derive from records; availability is checked at open time.)
- **Partial / failed / cancelled transfers**: define whether their files count toward stats and appear in recent media (see Assumptions — only successfully transferred files are counted by default).
- **Very large history**: Home previews are capped to a small number per section; See-all screens page/scroll the full set without loading everything into memory at once.
- **Live update**: completing or deleting a transfer record (e.g., from History) updates Home aggregates and recent lists without a restart.
- **Mixed/unknown file types**: a file that is neither image nor video is categorized as "File"; categorization is deterministic and documented.
- **Monthly count boundary**: "this month" is the user's current local calendar month; the count rolls over at the month boundary.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Home hero card MUST display the user's real cumulative bytes sent and bytes received, derived from the transfer history, replacing the placeholder summary.
- **FR-002**: The Home hero card MUST display the real number of transfers made in the current local calendar month.
- **FR-003**: The hero progress indicator MUST be derived from real data (e.g., the sent-vs-received ratio) and MUST NOT show a hardcoded value.
- **FR-004**: Each of the three stat tiles (Ảnh / Video / File) MUST display the real count of transferred items in that category.
- **FR-005**: The Recent photos, Recent videos, and Recent files sections MUST display real recently transferred items of the corresponding category, ordered newest-first, replacing placeholder tiles.
- **FR-006**: Each recent media item MUST show its real display metadata — name and size for all; a duration label for videos where the duration is known.
- **FR-006a**: The Recent photos grid (and its See-all screen) MUST display a **real image thumbnail** when the item's underlying file is available locally on disk (e.g., a received image). When the file is not available locally or cannot be read (e.g., a sent file with no durable path, or a deleted file), the item MUST fall back to a file-type icon on a design-token background. The Recent videos grid MUST display the video tile (play affordance + duration label where known) on a design-token background; a real decoded **video frame** is deferred to in-app viewers (#013) to avoid a native dependency in this feature. Image thumbnails MUST be loaded efficiently (no full-resolution media loaded into memory for a grid cell).
- **FR-007**: Tapping a recent media item (on Home or a See-all screen) MUST navigate to the existing History detail page (#006) for that item's transfer record, where the existing per-file Open / Share actions are available. (In-app preview is a later feature, #013.)
- **FR-008**: Each Home media section MUST provide a "Xem tất cả" (See all) affordance that opens a dedicated full-screen destination listing all items of that category.
- **FR-009**: Each See-all screen MUST have its own route and back navigation, list all items of its category (beyond the Home preview), and reuse the same item metadata and tap-to-open behavior as Home.
- **FR-010**: The system MUST show clear, localized empty states (VI primary + EN) for the hero (zeroed), each stat tile (zero), each Home media section, and each See-all screen when there is no corresponding data.
- **FR-011**: Home aggregates and recent lists MUST update without an app restart when the underlying transfer history changes (new transfer completes, record deleted, history cleared).
- **FR-012**: File categorization into Ảnh / Video / File MUST be deterministic and documented (by file type), and MUST classify any non-image/non-video file as "File".
- **FR-013**: The Home preview sections MUST be capped to a small fixed number of items per section; the full set is reached only via "Xem tất cả".
- **FR-014**: When a recent/See-all item's underlying file is unavailable on disk, the open action MUST surface a graceful localized message and MUST NOT crash.
- **FR-015**: The feature MUST reuse the existing transfer-history data and the existing Home "recent" data seam; it MUST NOT introduce a parallel/duplicate store of transfer data.
- **FR-016**: The recent media grids and the stat counts MUST be sourced **exclusively from the transfer history** (files that have been sent or received through the app). The feature MUST NOT read the device's on-device media library and MUST NOT require any new media-library permission. *(Decision 2026-06-29: transfer history only — keeps Home consistent with History (#006), requires no new permission, and matches the app's "files I transferred" meaning.)*
- **FR-017**: All new and changed user-facing strings MUST be provided via the existing localization mechanism (Vietnamese primary + English), including stat labels, section titles, "Xem tất cả", empty-state copy, and the file-unavailable message.

### Key Entities *(include if feature involves data)*

- **Transfer summary (hero)**: cumulative bytes sent, cumulative bytes received, count of transfers in the current calendar month, and a derived progress fraction.
- **Category stat**: a category (photos / videos / files) and the count of transferred items in it.
- **Recent media item**: a transferred file surfaced on Home / See-all — display name, size, category, optional duration (video), recency timestamp, direction (sent/received), a reference back to its transfer record, and a handle to open/preview it.
- **See-all collection**: the full ordered set of recent media items for a single category, backing a dedicated destination screen.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of the numeric values shown on Home (hero totals, monthly count, stat-tile counts) match the underlying transfer history for any given history state — zero hardcoded/mock numbers remain.
- **SC-002**: On a fresh install with no history, Home shows zeroed totals and empty states across every section, with no placeholder content visible.
- **SC-003**: After completing a transfer, the user sees Home reflect the new transfer (totals, counts, and the relevant recent section) on returning to Home without restarting the app.
- **SC-004**: Each of the three media sections has a working "Xem tất cả" destination that lists the complete category set and returns to Home on back, verified for all three categories.
- **SC-005**: Every recent/See-all item opens to the correct detail/open action, and an unavailable file produces a clear message rather than a crash, in 100% of attempts.
- **SC-006**: Browsing a large history (e.g., hundreds of items) in a See-all screen scrolls smoothly without loading the entire set into memory at once.

## Assumptions

- **Data source (decided, FR-016)**: **transfer history only** — "recent photos/videos/files" and the stat counts reflect files that have passed through the app (sent or received), requiring no new media-library permission and staying consistent with the existing history store (#006). On-device media-library indexing is **out of scope**.
- **Counted items**: only **successfully transferred** files count toward stats and appear in recent media; files from failed/cancelled transfers are excluded. Partial transfers count only the files that were fully received.
- **Both directions**: recent media and stat counts include both sent and received files (everything that moved through the app), not received-only.
- **"This month"**: the user's current **local calendar month**; the count resets at the month boundary.
- **Categorization**: by file type — image types → Ảnh, video types → Video, everything else → File.
- **Recency**: ordered by the transfer timestamp already recorded in history (#006).
- **Reuse**: the feature builds on the existing `HomeDashboard` view-model contract and the existing Home "recent" seam (#001 FR-008 / #006); the transfer-history store (#006) is the source of truth. No engine/signaling/transport/protocol/DB-schema changes are expected (additive read paths + new See-all screens only).
- **Depends on**: #001 (Home shell + shared widgets), #006 (transfer-history store + records).
- **Design**: the updated Home + See-all screens are pulled from the claude_design `SafeSend` project via `DesignSync` and distilled into the UI design context before UI work; the fixed light/dark palette and tokens are unchanged.
- **Out of scope**: editing or deleting media/files on the device; thumbnail generation for arbitrary formats beyond what existing previews provide; cloud/remote aggregates.
