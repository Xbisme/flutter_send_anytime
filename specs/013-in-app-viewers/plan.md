# Implementation Plan: In-App File Viewers

**Branch**: `013-in-app-viewers` | **Date**: 2026-06-29 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/013-in-app-viewers/spec.md`

## Summary

Tapping a **received** file of a known type opens it in an in-app viewer — image, a single shared video/audio player, PDF, or text/code — instead of bouncing to the OS share/open sheet; unsupported types and the sent side fall back to today's `open_filex`/share behavior unchanged. Real first-frame **video thumbnails** replace the play-glyph placeholder on Home/See-all grids (completing a #012 deferral), disk-cached across sessions. Everything renders **on-device** (no cloud), streams/loads within bounded memory, and is **additive** — no engine/signaling/transport/protocol/DB-schema edits.

Technical approach (from research.md): one new feature module `features/viewers/` plus a small core-pure launch coordinator + one dispatcher route. Three net-new packages, all version-verified against the Dart 3.11 / Flutter 3.41.7 floor: `video_player ^2.11.1` (video **and** audio), `pdfrx ^2.4.4` (on-device PDFium), `video_thumbnail_plus ^0.0.2` (thumbnails; the original `video_thumbnail` is incompatible with Dart 3.11). Image and text viewers use Flutter built-ins (no dep).

## Technical Context

**Language/Version**: Dart 3.11.5 / Flutter 3.41.7 (hard floor — pdfrx requires `flutter >=3.41.0`; do not downgrade)
**Primary Dependencies**: `video_player ^2.11.1`, `pdfrx ^2.4.4`, `video_thumbnail_plus ^0.0.2`; reuse `open_filex ^4.7.0`, `share_plus ^12.0.2`, `path_provider ^2.1.6`; built-in `InteractiveViewer` / `SelectableText`
**Storage**: No DB change. Disk thumbnail cache (LRU, ~64 MB) in the `path_provider` cache dir; keyed `videoPath+mtime`
**Testing**: `flutter_test` + `bloc_test` + `mocktail`; controllers abstracted behind `MediaController` / `VideoThumbnailService` seams so platform plugins aren't exercised in CI (loopback-style, Principle XII)
**Target Platform**: iOS 13+ / Android API 26+ (all new packages ≤ this floor: video_player iOS13/API24, video_thumbnail_plus iOS13/API24, pdfrx PDFium iOS12/API21)
**Project Type**: Mobile app (Flutter, Clean Architecture + feature-first)
**Performance Goals**: viewer opens <1s typical (SC-001); 60fps zoom/scroll; bounded memory on multi-hundred-MB PDF/video + long thumbnail lists (SC-005)
**Constraints**: on-device only (no bytes leave device — SC-008/FR-017); streamed I/O, never whole-file-in-memory (FR-018); text read capped 1 MiB; additive (no engine/schema edits)
**Scale/Scope**: 1 new feature module (4 viewer pages + dispatcher + 2 cubits), 1 launch coordinator, 2 core services, 1 resolver, ~3 entry-point edits, 1 new route; 3 packages

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ | Viewers render on-device only; no signaling/transport/TURN touch; no network. Airplane-mode test (SC-008). No file paths/contents logged. |
| II. Direct Transfer & Data Minimization | ✅ | No re-copy (FR-019); streamed/bounded reads (FR-018); thumbnails are derived, LRU-bounded, not "content" retention. |
| III. BLoC 4-state | ✅ | `MediaPlayerCubit` / `TextViewerCubit` are 4-state freezed; `@injectable` page-scoped; controllers disposed on close (FR-008). Image/PDF effectively stateless (justified — no business logic). |
| IV. Code Quality & Dart Safety | ✅ | very_good_analysis 0; explicit types; immutable states. |
| V. Result<T> Error Handling | ✅ | Services return `Result<T>`; cubits `.fold`; reuse existing `AppFailure.fileReadFailed`/`unknown` (no new variant — YAGNI). |
| VI. Design System & Theming | ✅ | Tokens only; file-type color system reused; Reduce-Motion respected; viewers are full-screen flows hiding bottom nav. |
| VII. Cross-Platform Native | ✅ | iOS + Android both; platform players (AVPlayer/ExoPlayer, PDFium, AVFoundation/MediaMetadataRetriever) ≤ floor; a11y labels on controls; haptics optional. |
| VIII. Transport & Signaling | ✅ | Untouched — no parallel progress, no protocol/state-machine edits. |
| IX. Transfer Reliability | ✅ | Untouched; viewers are read-only over already-saved files. |
| X. go_router Navigation | ✅ | New `AppRoutes.fileViewer` constant; `context.push/pop`; pushed on root navigator (hides nav); deep-link N/A. |
| XI. Feature-First Modularity | ✅ | `features/viewers/` imports no other feature; launch seam is core-pure (imports core only); `core/` imports no features. |
| XII. Testing Discipline | ✅ | Unit (resolver, cache, coordinator decision table), bloc_test (media/text cubits via fakes), widget tests (viewers). No two-device smoke (local feature) — manual per-type on-device pass is the deferred task. |
| XIII. Simplicity & YAGNI | ✅ | Built-ins for image/text; no chewie/photo_view/media_kit; reuse open/share; no PdfViewerCubit unless needed. |
| XIV. i18n by Default | ✅ | New ARB (VI primary + EN) for titles, truncated/unavailable/error copy, control a11y labels, with `@description`. |
| XV. Dependency Hygiene | ✅ | All 3 packages pub.dev-verified for version + SDK floor + min-OS + native footprint (research.md); incompatible `video_thumbnail 0.5.6` rejected; caret constraints; `pubspec.lock`/`Podfile.lock` committed. |

**Initial gate: PASS** (no violations → Complexity Tracking empty).
**Post-Phase-1 re-check: PASS** — the design adds one feature module + core-pure seams; no principle pressured. The only watch-item is pdfrx's Android native-assets build path → fallback `pdfx 2.9.2` documented (isolated to one page).

## Project Structure

### Documentation (this feature)

```text
specs/013-in-app-viewers/
├── plan.md              # This file
├── research.md          # Phase 0 — package verification + decisions
├── data-model.md        # Phase 1 — types, states, constants
├── quickstart.md        # Phase 1 — setup + manual verification
├── contracts/
│   └── viewer-routing.md # Phase 1 — route + coordinator + service seams
├── checklists/
│   └── requirements.md   # spec quality checklist (from /speckit.specify)
└── tasks.md             # Phase 2 — /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_routes.dart                      # + fileViewer
│   │   └── viewer_formats.dart                  # NEW: audio/pdf/text ext sets + caps
│   ├── domain/
│   │   └── viewer/viewer_request.dart           # NEW: ViewerRequest (router extra)
│   ├── services/
│   │   └── media/
│   │       ├── video_thumbnail_service.dart     # NEW: interface
│   │       ├── video_thumbnail_service_impl.dart# NEW: video_thumbnail_plus + disk LRU
│   │       ├── media_controller.dart            # NEW: seam interface
│   │       └── video_player_media_controller.dart # NEW: video_player impl
│   ├── utils/
│   │   └── file_viewer.dart                     # NEW: ViewerKind + ViewerResolver
│   ├── presentation/
│   │   ├── viewers/file_open_coordinator.dart   # NEW: core-pure launch seam
│   │   └── media/media_thumbnail.dart           # EDIT: video branch → thumbnail service
│   └── router/app_router.dart                   # EDIT: register fileViewer (root nav)
└── features/
    └── viewers/                                 # NEW feature module
        └── presentation/
            ├── pages/
            │   ├── file_viewer_page.dart        # dispatcher: switch on ViewerKind
            │   ├── image_viewer_view.dart       # InteractiveViewer + Image.file
            │   ├── media_player_page.dart        # video+audio (MediaPlayerCubit)
            │   ├── pdf_viewer_page.dart          # pdfrx PdfViewer.file
            │   └── text_viewer_page.dart         # SelectableText (TextViewerCubit)
            ├── cubit/
            │   ├── media_player_cubit.dart + state
            │   └── text_viewer_cubit.dart + state
            └── widgets/                          # transport controls, audio-only layout

lib/l10n/arb/                                     # EDIT: viewer copy (VI primary + EN)

# Entry-point edits (received side only → call openTransferredFile):
lib/features/history/presentation/history_detail_page.dart   # EDIT
lib/features/receive/presentation/pages/receive_transfer_page.dart # EDIT
lib/features/home/presentation/widgets/media_grid_item.dart  # EDIT (+ see_all)

ios/  android/                                    # pod install / native-assets (no new permissions)
```

**Structure Decision**: Mobile app, feature-first (Constitution XI). Viewer UI is a self-contained new feature `features/viewers/`; the cross-cutting launch decision + thumbnail/controller services live in `core/` (core imports no features; the launch coordinator routes via the `AppRoutes.fileViewer` constant, never importing a feature page). This mirrors the additive-seam pattern used since #004 (#005 `startReceiveOnTransport`, #012 `MediaThumbnail`).

## Phasing (for /speckit.tasks)

- **US1 Image (P1)** — packages + `ViewerKind`/`ViewerResolver` + `viewer_formats` + `ViewerRequest` + `AppRoutes.fileViewer` + `file_open_coordinator` + `FileViewerPage` dispatcher + image viewer; wire all 3 entry points (received) + sent/unsupported/unavailable fallbacks. ⇒ first independently shippable slice (also lands the shared plumbing).
- **US2 Media (P2)** — `MediaController` seam + `video_player` impl + `MediaPlayerCubit` + media player page (video + audio-only layout) + controls.
- **US3 Documents (P2)** — `pdfrx` PDF page + `TextViewerCubit` + text viewer (cap/truncate) + text/code allowlist.
- **US4 Thumbnails (P3)** — `VideoThumbnailService` + disk LRU cache + `MediaThumbnail` video branch (Home + See-all).
- Cross-cutting: ARB (VI+EN), a11y labels, Reduce-Motion, light/dark, error/empty states, tests per layer, native `pod install`.

## Complexity Tracking

> No Constitution violations — section intentionally empty.
