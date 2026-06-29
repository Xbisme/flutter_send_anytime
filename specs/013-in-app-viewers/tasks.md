---

description: "Task list for In-App File Viewers (#013)"
---

# Tasks: In-App File Viewers

**Input**: Design documents from `/specs/013-in-app-viewers/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/viewer-routing.md, quickstart.md

**Tests**: INCLUDED — Constitution XII mandates unit tests for logic, bloc_test for every Cubit, and widget tests for user-facing flows. Test tasks are grouped per story.

**Organization**: Tasks grouped by user story (priority order) for independent implementation + testing.

## Status Banner

- ✅ **Implemented (Dart)** 2026-06-29. `dart analyze lib test` = **0** · `flutter test` = **357 passed** (318 prior + 39 new) · `dart format` clean. All 4 user stories + foundational + polish gates + 2 device-run fixes done.
- **Device-run fix 1 (DI)**: `VideoThumbnailServiceImpl`'s optional-param constructor made injectable silently skip its registration — gave it a no-arg DI constructor + `.test` seam; added a DI-graph guard test (`viewers_registration_test.dart`).
- **Device-run fix 2 (stale iOS paths)**: rebuilds change the iOS data-container UUID, so the absolute received-file paths stored by #006 went stale even though the files migrate → old photos/videos/files showed as "unavailable". Added core-pure `ReceivedFilePath.resolve` (re-roots the stable `/SafeSend/…` tail on the current documents base, cached at bootstrap; read-only, no schema/migration) applied in `ReceivedFilesService.open/share`, the viewer coordinator, and `MediaThumbnail`. +7 tests (`received_file_path_test.dart`). This heals #005/#006 records, not just #013.
- **Test hardening**: the two `runAsync` real-I/O widget tests (text page, video thumbnail) used a fixed delay that flaked under full-suite parallel load → switched to poll-until-present (bounded retry). Verified 3× green in isolation.
- **Deferred (device-only, non-blocking)**: T046 first `pod install` since #011 (video_player + pdfrx/PDFium + thumbnail pods) + T047 manual on-device per-type viewer pass. No two-device smoke — local feature (like #012). T048 doc hygiene at merge.
- Toolchain: `flutter analyze` crashes on this checkout → use `dart analyze lib test`. bloc-lint CLI still uninstalled (tracked since #001).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: US1=Image · US2=Media · US3=Documents · US4=Thumbnails
- Mobile paths under `lib/` per plan.md Project Structure.

---

## Phase 1: Setup (Shared Infrastructure)

- [X] T001 Add dependencies in `pubspec.yaml`: `video_player ^2.11.1`, `pdfrx ^2.4.4`, `video_thumbnail_plus ^0.0.2` (versions verified in research.md); run `flutter pub get`; commit updated `pubspec.lock`.
- [X] T002 Run `dart run build_runner build --delete-conflicting-outputs` to confirm a clean baseline before adding freezed states / injectable registrations.
- [X] T003 Confirm baseline gates green: `dart format .` · `dart analyze lib test` (0) · `flutter test` (318 passed).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure, viewer-agnostic core shared by US1 (coordinator), US3 (text allowlist), and US4 (thumbnail categorization). No UI yet.

**⚠️ CRITICAL**: Complete before any user story phase.

- [X] T004 [P] Create `lib/core/constants/viewer_formats.dart`: `kAudioExts`, `kPdfExts`, `kTextExts` (allowlist per research.md), `kTextViewerCapBytes = 1 << 20`, `kVideoThumbMaxWidth = 320`, `kVideoThumbCacheMaxBytes = 64 << 20`.
- [X] T005 [P] Create `lib/core/utils/file_viewer.dart`: `enum ViewerKind { image, video, audio, pdf, text, unsupported }` + `ViewerResolver.of(String name, {String? mimeType})` (MIME-first, else extension sets; reuse #012 `FileCategory` image/video sets; audio/pdf/text from `viewer_formats`).
- [X] T006 [P] Create `lib/core/domain/viewer/viewer_request.dart`: immutable core-typed `ViewerRequest{ path, name, mimeType, kind }` (go_router extra for the dispatcher route).
- [X] T007 [P] [Tests] Unit test `test/core/utils/file_viewer_test.dart`: `ViewerResolver` acceptance matrix (each kind by MIME and by extension; ambiguous/no-ext → unsupported; audio splits out of #012 `files` bucket).
- [X] T008 Add ARB base keys (VI primary + EN, with `@description`) for cross-viewer copy: `viewerFileUnavailable`, `viewerOpenExternally`, `viewerErrorGeneric`, `viewerActionShare`, `viewerBack` in `lib/l10n/arb/app_vi.arb` + `app_en.arb`; regenerate l10n.

**Checkpoint**: Resolver + request + constants exist and are tested — viewer pages can now be built.

---

## Phase 3: User Story 1 - Preview a received image in-app (Priority: P1) 🎯 MVP

**Goal**: Tapping a received image from any of the 3 entry points opens a full-screen zoom/pan viewer; sent/unsupported/unavailable fall back exactly as today. Lands the shared routing plumbing (coordinator + dispatcher + route).

**Independent Test**: Receive a `.jpg`; tap it from History detail, Receive-complete, and a Home/See-all grid → full-screen image opens with pinch-zoom/pan, back returns to origin, share works. Tap a `.docx` → OS open/share fallback. Tap a sent file → fallback. Tap a deleted received file → "file unavailable".

### Implementation for User Story 1

- [X] T009 [US1] Add `static const fileViewer = '/viewer';` to `lib/core/constants/app_routes.dart` (with doc comment: root-navigator, `ViewerRequest` extra).
- [X] T010 [US1] Create core-pure launch coordinator `lib/core/presentation/viewers/file_open_coordinator.dart`: `Future<void> openTransferredFile(BuildContext, {required String name, required String? path, required String? mimeType, required bool isReceived})` implementing the decision table (sent→fallback FR-001; null/missing→unavailable FR-014; unsupported→fallback FR-004; else push `fileViewer`; re-entrancy guard FR-016). Imports core only (AppRoutes, ViewerRequest, ViewerResolver, ReceivedFilesService, AppToast).
- [X] T011 [US1] Create dispatcher `lib/features/viewers/presentation/pages/file_viewer_page.dart`: reads `ViewerRequest` extra, `switch (kind)` → image branch now (others added by US2/US3); full-screen `FlowAppBar` with back + share action (reuse `ReceivedFilesService.share`).
- [X] T012 [US1] Create `lib/features/viewers/presentation/pages/image_viewer_view.dart`: `InteractiveViewer` + `Image.file` with screen-bounded `cacheWidth` (OOM guard FR-018) + `errorBuilder` → localized error state (FR-015). GIF animates natively; HEIC best-effort.
- [X] T013 [US1] Register `AppRoutes.fileViewer` → `FileViewerPage` on the **root navigator** in `lib/core/router/app_router.dart` (full-screen, hides bottom nav — FR-020).
- [X] T014 [US1] Wire entry point — History detail: in `lib/features/history/presentation/history_detail_page.dart` replace the received-side `_openFile` body with `openTransferredFile(...)` (pass `isReceived: direction == received`, name/path/mime from `RecordedFile`); sent side unchanged.
- [X] T015 [US1] Wire entry point — Receive-complete: in `lib/features/receive/presentation/pages/receive_transfer_page.dart` route the file-tap `_open` through `openTransferredFile(... isReceived: true)`.
- [X] T016 [US1] Wire entry point — Home/See-all: in `lib/features/home/presentation/widgets/media_grid_item.dart` (and `see_all_page.dart` item tap) call `openTransferredFile(...)` from the `MediaItem` (`localPath`, `name`, mime via record, `isReceived` from `record.direction`); keep History-detail tap-through only when not viewable/unavailable per coordinator outcome.
- [X] T017 [P] [US1] [Tests] Unit/widget test `test/core/presentation/viewers/file_open_coordinator_test.dart`: full decision table (sent→fallback, missing→unavailable, unsupported→fallback, image→push fileViewer, double-tap no stack) with mocked `ReceivedFilesService` + a router probe.
- [X] T018 [P] [US1] [Tests] Widget test `test/features/viewers/image_viewer_test.dart`: renders `Image.file`, zoom gesture transforms, error file → error state + share affordance present.

**Checkpoint**: MVP — received images open in-app from all 3 surfaces; every other type/direction falls back cleanly.

---

## Phase 4: User Story 2 - Play a received video or audio file in-app (Priority: P2)

**Goal**: One shared player opens received video (full-screen frame) and audio (audio-only layout) with play/pause, scrubber, elapsed/total; playback stops + resources release on dismiss.

**Independent Test**: Receive a `.mp4` and an `.mp3`; tap each from History detail and Receive-complete → player opens, plays/pauses, seeks, shows correct times; audio shows audio-only layout; back stops playback (no background audio); a corrupt media file shows an error + share fallback.

### Implementation for User Story 2

- [X] T019 [P] [US2] Create test seam `lib/core/services/media/media_controller.dart`: `abstract class MediaController` (initialize/play/pause/seek/dispose + `progress` stream + `hasError` + `aspectRatio`) and `MediaProgress` value type.
- [X] T020 [US2] Create `lib/core/services/media/video_player_media_controller.dart`: `MediaController` impl wrapping `VideoPlayerController.file` (the only file importing `video_player`); maps to `MediaProgress`; `aspectRatio == 0` for audio-only.
- [X] T021 [P] [US2] Create `MediaPlayerState` (4-state freezed) in `lib/features/viewers/presentation/cubit/media_player_state.dart` (`loaded(MediaPlaybackView)` with mono-formatted elapsed/total via `Formatters`, `isAudioOnly`).
- [X] T022 [US2] Create `lib/features/viewers/presentation/cubit/media_player_cubit.dart` (`@injectable`): `init(path)` via `MediaController`, `togglePlay`/`seek`, subscribe→`loaded`, error→`error`; **dispose controller in `close()`** (FR-008).
- [X] T023 [US2] Create `lib/features/viewers/presentation/pages/media_player_page.dart` + `widgets/` (transport controls: play/pause, scrubber, time labels; video surface for `aspectRatio>0`, audio-only layout otherwise) with a11y labels + Reduce-Motion (no spinner churn).
- [X] T024 [US2] Add `video`/`audio` branches to `file_viewer_page.dart` dispatcher → `MediaPlayerPage` (BlocProvider page-scoped `MediaPlayerCubit`).
- [X] T025 [P] [US2] Add ARB keys (VI+EN) for media: play/pause/seek a11y labels, audio-only title, media error copy.
- [X] T026 [P] [US2] [Tests] bloc_test `test/features/viewers/media_player_cubit_test.dart` with a fake `MediaController`: init→loaded, toggle play/pause, seek updates position, error→error, **close disposes controller** (FR-008).
- [X] T027 [P] [US2] [Tests] Widget test `test/features/viewers/media_player_page_test.dart`: controls render; audio-only layout has no video box; time labels mono.

**Checkpoint**: US1 + US2 work independently — images and video/audio open in-app.

---

## Phase 5: User Story 3 - Read a received PDF or text/code file in-app (Priority: P2)

**Goal**: PDF opens in a paged pinch-zoom viewer; text/code opens readable + selectable (monospace for code) with a 1 MiB cap → truncated-with-notice; Office/unknown still fall back.

**Independent Test**: Receive a multi-page PDF, a `.txt`, and a `.json`; tap each from History detail → PDF pages/zooms, text renders selectable (mono for code); a >1 MB text shows truncated + "open externally" notice; a `.docx` falls back to OS open/share.

### Implementation for User Story 3

- [X] T028 [US3] Create `lib/features/viewers/presentation/pages/pdf_viewer_page.dart` using pdfrx `PdfViewer.file(path)` with its loading/error builders (on-device PDFium; paged scroll + pinch-zoom). If first build hits Android native-assets friction, swap to `pdfx 2.9.2` per research.md (isolated to this file).
- [X] T029 [P] [US3] Create `TextViewerState` (4-state freezed) in `lib/features/viewers/presentation/cubit/text_viewer_state.dart` (`loaded(text, truncated)`).
- [X] T030 [US3] Create `lib/features/viewers/presentation/cubit/text_viewer_cubit.dart` (`@injectable`): stream-read up to `kTextViewerCapBytes`; set `truncated` when larger; read failure → `error(fileReadFailed)`. Never load the whole large file (FR-010a/FR-018).
- [X] T031 [US3] Create `lib/features/viewers/presentation/pages/text_viewer_page.dart`: `SelectableText` (mono `TextStyle` for code exts) + truncated notice banner + open/share action.
- [X] T032 [US3] Add `pdf`/`text` branches to `file_viewer_page.dart` dispatcher (text branch provides `TextViewerCubit`).
- [X] T033 [P] [US3] Add ARB keys (VI+EN) for documents: text truncated notice, pdf/text error copy, viewer titles.
- [X] T034 [P] [US3] [Tests] bloc_test `test/features/viewers/text_viewer_cubit_test.dart`: small file→loaded(not truncated); >cap→loaded(truncated); unreadable→error.
- [X] T035 [P] [US3] [Tests] Widget test `test/features/viewers/text_viewer_page_test.dart`: selectable text + monospace for a code ext; truncated banner shown when `truncated`.

**Checkpoint**: US1–US3 — all supported types open in-app; everything else falls back.

---

## Phase 6: User Story 4 - Real video thumbnails in recent grids (Priority: P3)

**Goal**: Home recent video + See-all video tiles show a real first-frame thumbnail (play glyph overlaid), generated lazily, disk-cached across sessions (LRU), with play-glyph fallback when generation fails.

**Independent Test**: Receive several videos; open Home + See-all video list → tiles show real frames; scroll a long list → lazy + bounded memory; kill+reopen app → thumbnails reappear from disk cache (no re-decode); a corrupt video → play-glyph placeholder.

### Implementation for User Story 4

- [X] T036 [P] [US4] Create `lib/core/services/media/video_thumbnail_service.dart`: `abstract class VideoThumbnailService { Future<Result<String?>> thumbnailPath(String videoPath); }`.
- [X] T037 [US4] Create `lib/core/services/media/video_thumbnail_service_impl.dart` (`@LazySingleton(as: VideoThumbnailService)`): wrap `video_thumbnail_plus` (maxWidth `kVideoThumbMaxWidth`), disk cache in `path_provider` cache dir keyed `path+mtime`, LRU eviction at `kVideoThumbCacheMaxBytes`; never throws (→ `Result` failure). Logs no path (Principle I).
- [X] T038 [US4] Edit `lib/core/presentation/media/media_thumbnail.dart`: add a `videos` branch that asynchronously requests `VideoThumbnailService.thumbnailPath` and renders the decoded frame (bounded) with the play-glyph overlay; failure/none → existing `_IconFill` play-glyph fallback (FR-013). Keep the photo branch unchanged.
- [X] T039 [US4] Run `build_runner` to register the new `@lazySingleton` in the injectable graph; verify `getIt<VideoThumbnailService>()` resolves.
- [X] T040 [P] [US4] [Tests] Unit test `test/core/services/media/video_thumbnail_service_test.dart` with a fake generator + temp dir: cache miss generates+caches, cache hit returns same path, mtime change invalidates, generator failure → `Result` failure, LRU bound enforced.
- [X] T041 [P] [US4] [Tests] Widget test `test/core/presentation/media/media_thumbnail_video_test.dart`: video tile shows generated frame when service returns a path; falls back to play-glyph when it returns null/failure.

**Checkpoint**: All four stories functional and independently testable.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T042 [P] Verify ARB key parity VI↔EN (no missing keys) and every new key has `@description` (Constitution XIV).
- [X] T043 [P] A11y + Reduce-Motion + light/dark sweep across all four viewers + the thumbnail tiles (controls labeled; no motion churn; tokens only — Constitution VI/VII).
- [X] T044 [P] Log-hygiene pass: confirm no file path / name / bytes are logged by the coordinator, thumbnail service, or cubits (Principle I).
- [X] T045 Final gates: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all pass, target 318 + new). Fix any failures.
- [~] T046 Native build: **`pod install` ran** (added `video_player_avfoundation`, `pdfium_flutter`, `video_thumbnail_plus` → `ios/Podfile.lock` updated, commit at merge). **Remaining (device-only)**: full rebuild + confirm dev/prod build. No new permissions/Info.plist keys. NOTE: requires a *fresh* `flutter run` (not hot-reload) to link the new native pods — a hot-reloaded session throws `MissingPluginException`, handled gracefully (thumbnail→play-glyph fallback).
- [ ] T047 Manual on-device verification (deferred): run quickstart.md steps 1–10 per type incl. airplane-mode (SC-008), sent-side fallback, file-unavailable, and disk-cached thumbnails after relaunch. No two-device smoke (local feature).
- [ ] T048 [P] Docs: append the #013 changelog entry + flip status in `project-context.md` / `sdd-roadmap.md` at merge (per dev-workflow per-spec hygiene); refresh `ui-design-context.md` §Screen 06/07/01 note if the shipped viewers refine any screen.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (P1)**: no deps — start immediately.
- **Foundational (P2)**: depends on Setup — BLOCKS all user stories.
- **US1 (P3)**: after Foundational. Builds the coordinator + dispatcher + route → **US2/US3 depend on US1's dispatcher**.
- **US2 (P4)**, **US3 (P5)**: after US1 (add branches to the dispatcher — same file, so sequential there). Otherwise independent of each other.
- **US4 (P6)**: after Foundational only (uses `MediaCategory` + path_provider) — **independent of US1–US3**; can run in parallel with them.
- **Polish (P7)**: after the desired stories.

### Within Each Story
- Models/states (freezed) before cubits; cubits before pages; seam interfaces before impls.
- Tests [P] run alongside once their target file exists (Constitution XII — deterministic, mocktail).

### Parallel Opportunities
- T004/T005/T006/T007 (Foundational) are [P] (different files).
- US4 (T036–T041) can proceed in parallel with US1–US3 (different files; only `media_thumbnail.dart` shared with nobody else).
- All `[P]` test tasks within a story run together.
- `file_viewer_page.dart` dispatcher is edited by US1/US2/US3 → those edits are **sequential** (not [P]).

---

## Parallel Example: Foundational

```bash
Task: "T004 Create viewer_formats.dart constants"
Task: "T005 Create file_viewer.dart ViewerKind + ViewerResolver"
Task: "T006 Create viewer_request.dart"
Task: "T007 Unit test file_viewer_test.dart"
```

## Implementation Strategy

### MVP First (US1 only)
1. Phase 1 Setup → 2. Phase 2 Foundational → 3. Phase 3 US1 (image + shared routing) → **STOP & VALIDATE**: received images open from all 3 surfaces; all other types/directions fall back. Shippable.

### Incremental Delivery
US1 (MVP) → US2 (media) → US3 (documents) → US4 (thumbnails) → Polish. Each adds value without breaking prior stories. US4 can be slotted in any time after Foundational.

---

## Notes
- Additive only — **no engine/signaling/transport/protocol/DB-schema edits**.
- No new `AppFailure` variants (reuse `fileReadFailed`/`unknown` — YAGNI).
- `[P]` = different files, no incomplete deps. `[Story]` maps to spec.md user stories.
- Commit after each task or logical group; stop at any checkpoint to validate.
