# Data Model: In-App File Viewers (#013)

No persisted schema changes (no drift migration). All types below are in-memory / presentation models, except the disk thumbnail cache which is a file-backed key→file map (not a DB).

---

## Core types (`lib/core/`)

### `ViewerKind` (enum) — `core/utils/file_viewer.dart`
The routing decision for a tapped file.
```
enum ViewerKind { image, video, audio, pdf, text, unsupported }
```

### `ViewerResolver` — `core/utils/file_viewer.dart`
Pure, I/O-free classification of a file → `ViewerKind`.
- `static ViewerKind of(String name, {String? mimeType})`
- Rule: MIME wins when present (`image/*`→image, `video/*`→video, `audio/*`→audio, `application/pdf`→pdf, `text/*`→text); else match extension against fixed sets (image/video reuse #012's `FileCategory` sets; audio/pdf/text/code sets defined in `core/constants/viewer_formats.dart`); otherwise `unsupported`.

### `ViewerRequest` — `core/domain/viewer/viewer_request.dart`
The go_router `extra` for `AppRoutes.fileViewer`. Core-typed (so features never import each other).
| Field | Type | Notes |
|---|---|---|
| `path` | `String` | On-disk path of a **received** file (verified to exist before push). |
| `name` | `String` | Display name (title bar). |
| `mimeType` | `String?` | When known (from the history record). |
| `kind` | `ViewerKind` | Resolved supported kind (never `unsupported` here). |

### `VideoThumbnailService` — `core/services/media/video_thumbnail_service.dart` (`@lazySingleton`)
Interface:
- `Future<Result<String?>> thumbnailPath(String videoPath)` — returns a cached/generated JPEG path, or `null` (success-but-none) when generation isn't possible; never throws.
Behavior: key = `videoPath + mtime`; on hit returns the cached file; on miss generates via `video_thumbnail_plus` (maxWidth ≈320), writes into the `path_provider` cache dir, enforces an LRU size bound (~64 MB), and returns it. Failures → `Result` failure → caller falls back to the play-glyph.

### `MediaController` (seam) — `core/services/media/media_controller.dart`
Thin interface over `video_player` for testability (impl `VideoPlayerMediaController` wraps `VideoPlayerController.file`; a fake backs cubit tests).
- `Future<void> initialize()`, `play()`, `pause()`, `seek(Duration)`, `dispose()`
- streams/getters: `position`, `duration`, `isPlaying`, `hasError`, `aspectRatio` (0 / no-video → audio-only layout).

---

## Feature types (`lib/features/viewers/`)

### `MediaPlayerState` (4-state freezed) — video + audio
```
initial
loading
loaded({ required MediaPlaybackView view })   // position, duration, playing, isAudioOnly
error({ required AppFailure failure })
```
- `MediaPlaybackView` is a display-ready projection (mono-formatted elapsed/total via `Formatters`).
- `MediaPlayerCubit` (`@injectable`): `init(path)` → `MediaController.initialize` → subscribe → `loaded`; `togglePlay()`, `seek()`; **`close()` disposes the controller** (FR-008).

### `TextViewerState` (4-state freezed)
```
initial
loading
loaded({ required String text, required bool truncated })
error({ required AppFailure failure })
```
- `TextViewerCubit` (`@injectable`): reads up to `kTextViewerCapBytes` (1 MiB); if the file is larger, sets `truncated = true`; read failure → `error(fileReadFailed)`.

### Image viewer — stateless
`InteractiveViewer` + `Image.file(cacheWidth: screenBounded, errorBuilder: → error state)`. No cubit.

### PDF viewer — pdfrx-managed
Uses `PdfViewer.file(path)` with pdfrx's own loading/error builders. No cubit (lean; revisit only if a custom error surface is required).

---

## Constants — `core/constants/viewer_formats.dart`
- `kAudioExts`, `kPdfExts = {pdf}`, `kTextExts` (the allowlist in research.md).
- `kTextViewerCapBytes = 1 << 20`.
- `kVideoThumbMaxWidth = 320`, `kVideoThumbCacheMaxBytes = 64 << 20`.

## Relationships / flow
```
tap (History detail | Receive-complete | Home/See-all)
   └─> core/presentation/viewers/openTransferredFile(context, {path,name,mime,direction})
         ├─ direction == sent            → ReceivedFilesService.open (fallback)         [FR-001]
         ├─ !File(path).exists           → "file unavailable" toast/state               [FR-014]
         ├─ ViewerResolver.of == unsupported → ReceivedFilesService.open (fallback)      [FR-004]
         └─ else → context.push(AppRoutes.fileViewer, extra: ViewerRequest)             [FR-001]
                     └─ FileViewerPage switches on kind → image | media | pdf | text viewer
```

No new `AppFailure` variants; reuse `fileReadFailed` / `unknown`. No DB tables, no protocol/manifest changes.
