# Feature Specification: In-App File Viewers

**Feature Branch**: `013-in-app-viewers`  
**Created**: 2026-06-29  
**Status**: Draft  
**Input**: User description: "In-App File Viewers (Spec #013) — the last v1.0 feature spec before Polish. Tapping a transferred file of a known type opens it in an in-app viewer (image / video / audio / PDF / text-code) instead of bouncing to the OS share/open sheet; unsupported types fall back to the existing open/share behavior. Also generates real video thumbnails for the Home recent grids (completing a #012 deferral). On-device rendering only, streamed/efficient loading. Builds on #005/#006/#012; additive only."

## Clarifications

### Session 2026-06-29

- Q: Khi user tap một file ở phía đã gửi (sent) trong History, có mở viewer in-app không, hay luôn fallback open/share? → A: Chỉ file đã **nhận** (received) mở viewer in-app; file đã **gửi** luôn dùng fallback open/share (received paths nằm trong sandbox `/SafeSend` → ổn định; sent paths thường tạm/security-scoped → không bền).
- Q: Video thumbnail cache ở đâu — đĩa bền qua phiên hay chỉ in-memory? → A: Cache **trên đĩa, bền qua các phiên**, key theo file path + mtime, có giới hạn dung lượng + dọn LRU; sinh frame một lần rồi tái dùng (tránh decode lại mỗi lần mở app).
- Q: Text viewer xử lý file văn bản lớn thế nào? → A: Đọc tới **ngưỡng cap (~1 MB)** rồi hiển thị phần đầu (truncated) kèm thông báo "đã cắt bớt" + hành động open/share để xem đầy đủ; không bao giờ nạp cả file lớn vào bộ nhớ. Ngưỡng cụ thể chốt ở plan.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Preview a received image in-app (Priority: P1)

A user who has just received (or earlier received) one or more image files taps an image from the Receive-complete list, the History detail page, or a Home recent grid. Instead of being thrown out to another app, the image opens full-screen inside Safe Send, where the user can pinch-to-zoom and pan, then go back to where they were. From the viewer the user can still share or open the file in another app if they want to.

**Why this priority**: Images are the most frequently shared file type and the simplest to preview reliably. This single slice delivers the core "see it without leaving the app" value and establishes the shared launch + fallback + export plumbing that every other viewer reuses. It is a complete, demonstrable MVP on its own.

**Independent Test**: Receive an image, tap it from each of the three entry points, confirm it opens full-screen with zoom/pan, back returns to the originating screen, and the share/open action still works. Tapping a non-image still behaves exactly as today.

**Acceptance Scenarios**:

1. **Given** a received `.jpg` that exists on disk, **When** the user taps it in the Receive-complete list, **Then** a full-screen image viewer opens showing the image, with a back control and a share/open action.
2. **Given** the image viewer is open, **When** the user pinch-zooms and pans, **Then** the image scales and moves smoothly and a reset/back returns to the previous screen.
3. **Given** a received image shown in a Home recent grid, **When** the user taps it, **Then** the same image viewer opens (the viewer behaves identically regardless of which surface launched it).
4. **Given** an image file that is recorded in history but no longer present on disk, **When** the user taps it, **Then** a clear "file unavailable" state is shown (no crash) and no empty viewer appears.

---

### User Story 2 - Play a received video or audio file in-app (Priority: P2)

A user taps a received video or audio file from any of the three entry points. A single in-app media player opens — full-screen with the video frame for video, and a graceful audio-only layout (file name + art/placeholder) for audio — offering play/pause, a draggable scrubber, and elapsed/total time. The user can watch/listen, then go back. Share/open-in remains available.

**Why this priority**: Video and audio are common transfers and a major reason users currently leave the app. One shared player covers both with consistent controls. It depends on the same routing/fallback plumbing from US1, so it follows naturally.

**Independent Test**: Receive a short video and an audio file; tap each from History detail and the Receive-complete list; confirm the player opens, plays/pauses, scrubs, shows correct elapsed/total time, and returns cleanly. An audio file shows the audio-only layout; a video shows the frame.

**Acceptance Scenarios**:

1. **Given** a received `.mp4` on disk, **When** the user taps it, **Then** a full-screen player opens and begins/holds at the first frame with play/pause, scrubber, and elapsed/total time.
2. **Given** the player is playing, **When** the user drags the scrubber, **Then** playback seeks to that position and the elapsed time updates accordingly.
3. **Given** a received audio file (e.g. `.mp3`/`.m4a`), **When** the user taps it, **Then** the player opens in an audio-only layout (no black video area) with the same transport controls.
4. **Given** the player is open, **When** the user leaves the viewer (back) or the file ends, **Then** playback stops and resources are released (no audio continues in the background).
5. **Given** a media file that is corrupt or unreadable, **When** the user opens it, **Then** a clear error state is shown with the option to share/open externally instead.

---

### User Story 3 - Read a received PDF or text/code file in-app (Priority: P2)

A user taps a received PDF or a plain-text/code file. A PDF opens in a paged document viewer that scrolls/pages through pages with pinch-zoom; a text or code file opens in a readable text viewer (monospace for code) with selectable text. The user can read, then go back, and still share/open externally.

**Why this priority**: PDFs and text/code are common document transfers and complete the "consume what you received" promise for non-media files. Documents are heavier to render than images, so they follow the media slice but remain in-scope for v1.0.

**Independent Test**: Receive a multi-page PDF and a `.txt`/source file; tap each from History detail; confirm the PDF pages/scrolls and zooms, the text renders readably with selectable text and monospace for code, and both offer share/open. An Office document (e.g. `.docx`) instead falls back to the OS open/share handoff.

**Acceptance Scenarios**:

1. **Given** a received multi-page PDF on disk, **When** the user taps it, **Then** a paged document viewer opens showing page 1, allowing scroll/page navigation and pinch-zoom.
2. **Given** a received `.txt` file, **When** the user taps it, **Then** a readable text viewer opens with selectable text.
3. **Given** a received source-code file (e.g. `.json`, `.dart`, `.md`), **When** the user taps it, **Then** the text viewer opens rendering its content in a monospace style.
4. **Given** a received `.docx`/`.xlsx`/`.pptx` or other unsupported type, **When** the user taps it, **Then** Safe Send falls back to the existing OS open/share behavior (never a dead end).
5. **Given** a text file larger than the ≈1 MB cap, **When** the user taps it, **Then** the text viewer shows the leading portion with a "content truncated — open externally to view all" notice plus a share/open-in action, and the UI never freezes.

---

### User Story 4 - Real video thumbnails in recent grids (Priority: P3)

When browsing the Home recent video section, the See-all video list, or History, the user sees a real first-frame thumbnail of each video instead of a generic play-glyph placeholder, so they can recognize content at a glance. Thumbnails appear lazily as the list scrolls and never bloat memory.

**Why this priority**: This is recognized polish that completes a deliberate #012 deferral, made cheap by the media capability added in US2. It is user-visible but not required for the core preview value, so it is lowest priority.

**Independent Test**: Receive several videos; open Home, the See-all video list, and History; confirm each video tile shows a representative still frame (with the play glyph overlaid), thumbnails fill in lazily while scrolling, and memory stays bounded with many videos.

**Acceptance Scenarios**:

1. **Given** received videos on disk, **When** the user views the Home recent video section, **Then** each tile shows a real first-frame thumbnail with a play affordance overlay.
2. **Given** a video whose thumbnail cannot be generated (corrupt/unsupported codec), **When** its tile is shown, **Then** it falls back to the existing play-glyph placeholder (no crash, no blank tile).
3. **Given** a long video list, **When** the user scrolls quickly, **Then** thumbnails load lazily and memory usage stays bounded.

---

### Edge Cases

- **File no longer on disk**: a history record references a file whose path no longer exists (received file deleted, or sent-only record whose source was removed) → show a clear "file unavailable" state; never open an empty viewer or crash.
- **Zero-byte / empty file**: opening yields a graceful "empty file" / error state with the share-out option, not a hang.
- **Corrupt or unreadable file** (truncated media, malformed PDF, undecodable text encoding) → error state with fallback to OS open/share.
- **Unsupported but plausible type** (Office docs, archives, unknown extension) → fallback to existing OS open/share exactly as today.
- **Ambiguous type** (extension and content disagree, or no extension) → categorize via the existing file classification; if it does not resolve to a supported viewer, fall back.
- **Very large media / PDF** (multi-hundred-MB) → must load efficiently without reading the whole file into memory; viewer remains responsive.
- **Sent files**: outgoing history records never open an in-app viewer (per FR-001) — tapping a sent file always uses the existing OS open/share handoff, which itself degrades cleanly if the source is gone.
- **Interruptions during media playback** (incoming call, app backgrounded, screen lock) → playback pauses/stops cleanly and audio does not leak in the background.
- **Reduced Motion / accessibility**: viewers respect Reduced-Motion; player controls and the back/share actions carry accessibility labels.
- **Rapid re-taps / double-open**: tapping a file while a viewer is opening must not stack duplicate viewers.

## Requirements *(mandatory)*

### Functional Requirements

**Viewer launch & routing**

- **FR-001**: The system MUST open a supported **received** file in an in-app viewer when the user taps it from any of the three entry points: the History detail file list, the Receive-complete file list, and the Home recent grids (including the "Xem tất cả" See-all screens). Files on the **sent** side (outgoing history records) MUST NOT open an in-app viewer; tapping a sent file MUST use the existing OS open/share behavior (its source path is typically temporary/security-scoped and not reliably re-openable).
- **FR-002**: The system MUST determine which viewer to use from the file's type using a viewer-kind resolver that reuses the #012 file classification (and splits audio / PDF / text/code out of its `files` bucket), routing image → image viewer, video/audio → media player, PDF → document viewer, and text/code → text viewer.
- **FR-003**: The viewer behavior MUST be identical regardless of which surface launched it (the viewer is launch-source agnostic).
- **FR-004**: For any file type NOT supported in-app (e.g. Office docx/xlsx/pptx, archives, unknown types), the system MUST fall back to the existing OS open/share behavior unchanged — the user MUST never reach a dead end.

**Supported viewers**

- **FR-005**: The system MUST provide a full-screen image viewer supporting pinch-to-zoom and pan for common image formats (jpg, jpeg, png, gif, webp, heic, heif, bmp, tiff).
- **FR-006**: The system MUST provide a single shared media player that plays both video and audio, offering play/pause, a draggable scrubber/seek, and elapsed/total time.
- **FR-007**: The media player MUST present video full-screen with the video frame and audio with a graceful audio-only layout (no empty/black video area).
- **FR-008**: The media player MUST stop playback and release media resources when the viewer is dismissed or the app is backgrounded, so no audio continues unexpectedly.
- **FR-009**: The system MUST provide a paged PDF document viewer supporting page navigation (scroll/paging) and pinch-zoom.
- **FR-010**: The system MUST provide a text viewer for plain-text and source-code files that renders readable, selectable text and uses a monospace style for code.
- **FR-010a**: The text viewer MUST read at most a bounded cap (≈1 MB, exact value set at plan) and never load an entire large text file into memory. When a file exceeds the cap, the viewer MUST show the leading portion with a clear "content truncated — open externally to view all" notice plus the share/open-in action.
- **FR-011**: Every in-app viewer MUST provide a back affordance returning the user to the originating screen and a share/open-in action that reuses the existing OS share/open behavior.

**Video thumbnails**

- **FR-012**: The system MUST display a real first-frame thumbnail for video items shown in the **media-grid surfaces** — the Home recent video grid and the See-all video list — replacing the current play-glyph placeholder, with a play affordance overlaid. (The History tab list and History detail use direction avatars / icon `FileRow`s, not media grids, and are intentionally out of scope for video thumbnails.)
- **FR-013**: Video thumbnails MUST load lazily (as items become visible) and within bounded memory; when a thumbnail cannot be generated, the tile MUST fall back to the existing play-glyph placeholder.
- **FR-013a**: Generated video thumbnails MUST be cached on disk and persist across app sessions (keyed by file path + last-modified time) so a frame is decoded at most once per video; the cache MUST be size-bounded with LRU eviction and MUST NOT grow without limit.

**File availability & errors**

- **FR-014**: Before opening a viewer (received files only, per FR-001), the system MUST verify the file exists and is readable on disk; if it does not exist (e.g. a deleted received file), the system MUST show a clear "file unavailable" state instead of opening a viewer.
- **FR-015**: For corrupt, unreadable, zero-byte, or otherwise un-renderable files, each viewer MUST show a clear error state offering the OS open/share fallback rather than crashing or hanging.
- **FR-016**: Opening a viewer MUST NOT stack duplicate viewers when the user taps the same item repeatedly in quick succession.

**Privacy, performance & platform**

- **FR-017**: All viewers MUST render files entirely on-device; the system MUST NOT upload, proxy, or transmit file bytes to any cloud or remote service (preserving the "no intermediary server holds the data" promise).
- **FR-018**: Viewers MUST load media and documents efficiently without reading an entire large file into memory, remaining responsive for large videos and multi-hundred-MB PDFs.
- **FR-019**: Viewers MUST reuse the existing on-disk file paths from the receive/history flows; the system MUST NOT re-copy or duplicate file bytes to open a viewer.
- **FR-020**: Viewers are full-screen flows that MUST hide the bottom navigation while shown.
- **FR-021**: All viewer UI copy MUST be provided via the app's localization (Vietnamese primary + English) and follow the existing design tokens, file-type color system, light/dark palette, and Reduced-Motion behavior, with accessibility labels on player controls and primary actions.

### Key Entities *(include if feature involves data)*

- **Viewable file reference**: a transferred file the user can attempt to open — derived from existing receive/history records. Key attributes (already present from #005/#006): on-disk path, display name, type/MIME (used by the existing classification), size, and direction (sent/received). No new persisted entity is introduced.
- **Media category** (existing): the photos / videos / files / document buckets the classification produces, extended in interpretation to select the correct viewer (image vs media vs PDF vs text vs fallback).
- **Video thumbnail**: a lazily-generated first-frame preview keyed by video file path + last-modified time; cached on disk and persisted across sessions within a size-bounded, LRU-evicted cache (decoded at most once per video).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: From any of the three entry points, tapping a supported file opens its in-app viewer in under 1 second for typical files (small/medium images, short media, single-page PDFs).
- **SC-002**: 100% of file taps result in a defined outcome — a working viewer, a clear "file unavailable"/error state, or the OS open/share fallback — with zero crashes across all supported and unsupported types.
- **SC-003**: Every supported type (image, video, audio, PDF, text/code) opens and is consumable (zoom/pan, play/seek, page/scroll, read/select) without leaving the app.
- **SC-004**: Unsupported types (Office, archives, unknown) reach the existing OS open/share fallback in 100% of cases — no dead ends and no behavior regression versus today.
- **SC-005**: Opening and scrolling viewers/thumbnails for large files (multi-hundred-MB PDF/video, long video lists) keeps the app responsive and within a bounded memory ceiling — no out-of-memory or sustained frame drops.
- **SC-006**: After viewing, dismissing a media viewer stops playback in 100% of cases (no background audio leak) and returns the user to the exact originating screen.
- **SC-007**: Video tiles in Home/See-all/History show a representative still frame for at least the common video formats, with a graceful placeholder fallback when generation is not possible.
- **SC-008**: No file bytes leave the device to render any viewer (verifiable: viewers function fully in airplane mode for files already on disk).

## Assumptions

- **Document scope is PDF + text/code only for v1.0** (confirmed at pre-spec): Office formats (docx/xlsx/pptx) are intentionally out of scope and fall back to OS open/share, because on-device Office rendering is heavy and typically requires a conversion/cloud step that would conflict with the no-server privacy promise.
- **A single shared media player handles both video and audio** (confirmed at pre-spec) rather than separate viewers, for consistent controls and less surface area.
- **Real video thumbnails are in scope for #013** (confirmed at pre-spec), completing the #012 deferral, since the media capability needed already lands in this spec.
- **Text/code "common formats"** = files the existing classification treats as non-image/non-video text, plus a fixed allowlist of plain-text/source extensions (e.g. txt, md, json, xml, csv, log, yaml, and common source-code extensions). Binary/unknown types are not forced into the text viewer.
- **Large-text guard** (clarified): the text viewer reads at most ≈1 MB and shows a truncated-with-notice preview (+ open/share) for larger files so a multi-hundred-MB text file cannot freeze the UI; the exact cap is a plan-time detail.
- **Reuses existing on-disk paths**: viewers read the same files saved by #005 (received-files sandbox) and referenced by #006 history; no new storage, permissions, or copies are introduced.
- **Additive only**: no changes to the transfer engine, signaling, transport, protocol, or DB schema are expected; the existing share/open fallback (open_filex / share_plus) is reused for export and for unsupported types.
- **Local files only**: only files already transferred and present on this device are viewable; remote/URL/streaming media is out of scope.
- **Native viewer packages** (media playback, PDF rendering, video thumbnail generation) will be selected and version/min-OS-verified at `/speckit.plan` per Constitution XV; this spec stays implementation-agnostic. This is expected to be the first spec since #007 that may require a fresh `pod install`.

## Dependencies

- **#005 Receive Flow** — provides the on-disk received-file paths and the Receive-complete file list entry point.
- **#006 History** — provides transfer records, the History detail entry point, and the file metadata (path, name, type, size) the viewers consume.
- **#012 Home Completion** — provides the Home recent grids + See-all screens entry points and the `FileCategory` classification reused to route files to viewers and to identify video tiles for thumbnails.

## Out of Scope (v1.0)

- Editing or annotating any file.
- In-app viewing of Office formats (docx/xlsx/pptx) — falls back to OS open/share.
- Thumbnail generation for arbitrary/unknown formats (only video first-frame thumbnails are added; image thumbnails already exist from #012).
- Streaming remote or URL-based media — only local transferred files.
- Casting/AirPlay, slideshow, or gallery-style swiping between multiple files (single-file open per tap for v1.0).
