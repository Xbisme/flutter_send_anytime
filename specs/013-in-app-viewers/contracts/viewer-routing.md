# Contract: Viewer Routing & Service Interfaces (#013)

This feature exposes no network/API contracts (it is an on-device UI feature). The "contracts" here are the **internal seams** other code binds to: one route, one launch function, two service interfaces. Keeping these stable is what lets the three entry points share behavior (FR-003) without features importing each other (Constitution XI).

---

## 1. Route contract

```
AppRoutes.fileViewer = '/viewer'
```
- **Pushed on**: the **root navigator** (full-screen, hides bottom nav — FR-020, Constitution X).
- **extra**: `ViewerRequest` (core type). The page asserts `request.kind != ViewerKind.unsupported`.
- **Navigation API**: `context.push(AppRoutes.fileViewer, extra: request)`. Back via `context.pop()`.
- Registered in `core/router/app_router.dart`; the route binds `FileViewerPage` from `features/viewers/` — `core/` references the route constant only, not the page import path at call sites.

## 2. Launch function contract (core-pure coordinator)

`lib/core/presentation/viewers/file_open_coordinator.dart`
```dart
Future<void> openTransferredFile(
  BuildContext context, {
  required String name,
  required String? path,
  required String? mimeType,
  required bool isReceived,   // false (sent) → always OS fallback
});
```
Decision table (the single source of viewer-vs-fallback behavior):

| Condition | Action | Spec |
|---|---|---|
| `!isReceived` (sent) | `ReceivedFilesService.open(path)` (or share) | FR-001 |
| `path == null` or file missing/unreadable | show "file unavailable" (toast/state), no viewer | FR-014 |
| `ViewerResolver.of(name, mime) == unsupported` | `ReceivedFilesService.open(path)` fallback | FR-004 |
| otherwise | `context.push(fileViewer, extra: ViewerRequest(path,name,mime,kind))` | FR-001 |
| same item tapped twice rapidly | guarded (re-entrancy flag) → no stacked viewers | FR-016 |

- Imports: `AppRoutes`, `ViewerRequest`, `ViewerResolver`, `ReceivedFilesService`, `AppToast`. **No feature imports.**
- All three entry points replace their current `open(...)` call (received side) with `openTransferredFile(...)`; the sent side is unchanged (still falls back).

## 3. `VideoThumbnailService` (core/services/media)
```dart
abstract class VideoThumbnailService {
  /// Cached/generated thumbnail JPEG path, or null when none is possible.
  /// Never throws; failures map to Result failure (caller → play-glyph).
  Future<Result<String?>> thumbnailPath(String videoPath);
}
```
- DI: `@LazySingleton(as: VideoThumbnailService)`.
- Cache: disk, key `videoPath + mtime`, LRU-bounded (`kVideoThumbCacheMaxBytes`).
- Consumer: `MediaThumbnail` (core/presentation) video branch → upgrades Home + See-all video tiles (FR-012/013); graceful fallback to play-glyph (FR-013).

## 4. `MediaController` (core/services/media) — test seam
```dart
abstract class MediaController {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
  Stream<MediaProgress> get progress;     // position, duration, isPlaying
  bool get hasError;
  double get aspectRatio;                  // 0 → audio-only layout
}
```
- Impl `VideoPlayerMediaController` wraps `VideoPlayerController.file` (the only place `video_player` is imported).
- Enables `MediaPlayerCubit` bloc tests with a fake (platform plugin not exercised in CI — mirrors #002/#011).

---

## Invariants
- **On-device only**: no viewer issues any network request; all four viewers function in airplane mode for on-disk files (SC-008, FR-017).
- **No re-copy**: viewers read the existing received-file path; no duplication (FR-019).
- **Resource release**: dismissing the media viewer disposes the controller (FR-008); pdfrx/image release on page dispose.
- **Bounded memory**: text capped (1 MiB); image decoded screen-bounded; pdf rendered per-page; thumbnails small + LRU (FR-018, SC-005).
