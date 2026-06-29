# Research: In-App File Viewers (#013)

**Date**: 2026-06-29 · **Branch**: `013-in-app-viewers`
**SDK floor (hard constraint)**: Dart `^3.11.0` (local 3.11.5) · Flutter `3.41.7`. Every package below was version-verified against this floor via the pub.dev API (`/api/packages/<name>` → `environment`) per Constitution XV. Latest releases that require Dart ≥3.12 / Flutter ≥3.44 are explicitly rejected.

---

## Decision summary (packages)

| Need | Decision | Version | Why this / not the obvious latest |
|---|---|---|---|
| Image zoom/pan viewer | **Flutter built-in** `InteractiveViewer` + `Image.file` | — (no dep) | Covers pinch-zoom/pan (FR-005) with zero new native code; Principle XIII (prefer stdlib). `photo_view` considered, rejected (extra dep for double-tap nicety only). |
| Video **and** audio player (one shared) | **`video_player`** (flutter.dev) | `^2.11.1` | Official, AVPlayer/ExoPlayer → plays both video and audio files; `sdk ^3.10.0, flutter >=3.38.0` ✓; iOS 13 / Android 24 ≤ project floor. Custom shared transport controls (no `chewie` — its chrome is video-centric; YAGNI). |
| PDF viewer | **`pdfrx`** | `^2.4.4` | PDFium (on-device, no cloud → FR-017), texture-rendered (smooth zoom for large PDFs → FR-018/SC-005), actively maintained (pub 2026-06-13, 349k weekly); `sdk ^3.10.0, flutter >=3.41.0` ✓ exactly the project floor. Fallback documented: `pdfx 2.9.2`. |
| Text/code viewer | **Flutter built-in** (`dart:io` read + `SelectableText`) | — (no dep) | Capped read (~1 MB) into `SelectableText` with a mono `TextStyle` (FR-010/010a). No package needed; Principle XIII. |
| Video first-frame thumbnail | **`video_thumbnail_plus`** | `^0.0.2` | Maintained fork of `video_thumbnail`; `sdk >=2.12.0 <4.0.0` ✓, iOS 13 / Android 24 ≤ floor. The original `video_thumbnail 0.5.6` is **rejected** — `sdk >=2.16.0 <3.0.0` excludes Dart 3.11 (won't resolve). |
| Open/share fallback + file I/O | **reuse existing** `open_filex ^4.7.0`, `share_plus ^12.0.2`, `path_provider ^2.1.6` | — | Unsupported types + the in-viewer export action reuse the #005/#006 plumbing; thumbnail cache dir from `path_provider`. No new dep. |

**Net new packages: 3** — `video_player`, `pdfrx`, `video_thumbnail_plus`. All resolve on Dart 3.11 / Flutter 3.41.7.

---

## Per-package verification detail (Constitution XV)

### video_player `^2.11.1`
- **environment**: `sdk ^3.10.0`, `flutter >=3.38.0` → satisfied by 3.11.5 / 3.41.7.
- **Min OS**: iOS 13.0, Android API 24. Project floor is iOS 13 / Android 26 → ✓ no `minSdk`/deployment bump.
- **Native**: `video_player_avfoundation` (iOS, AVPlayer) + `video_player_android` (ExoPlayer). First `pod install` since #011 will add the AVFoundation pod (expected `Podfile.lock` churn).
- **Audio-only**: AVPlayer/ExoPlayer decode audio containers (mp3/m4a/aac/wav); the player surface is simply empty → we render an audio-only layout (FR-007). Exotic/unsupported codecs surface as a clean error (FR-015).
- **Info.plist / manifest**: none required for **local file** playback (no `NSAppTransportSecurity`, no network). No new permission.
- **Testability**: wrap the controller behind a thin `MediaController` interface (impl over `VideoPlayerController.file`) so `MediaPlayerCubit` is unit/bloc-testable with a fake — mirrors the #002/#011 seam pattern (platform plugin not exercised in CI).

### pdfrx `^2.4.4`
- **environment**: `sdk ^3.10.0`, `flutter >=3.41.0` → satisfied (project 3.41.7; note: a tight floor — do not downgrade Flutter below 3.41.0).
- **Engine**: PDFium, rendered **on-device**; no cloud/remote (FR-017). Texture-based → pages render on demand (streamed, bounded memory; FR-018).
- **Native packaging**: Android/Linux/Windows bundle PDFium via **Dart native assets**; iOS/macOS link the **PDFium XCFramework via CocoaPods**. No `flutter config --enable-native-assets` flag called out in the README; Flutter 3.41 supports the native-assets path. First `pod install` adds the pdfrx/PDFium pod.
- **Min OS**: not stated explicitly; PDFium-class plugins are iOS 12+/Android 21+ → within the iOS 13 / Android 26 floor. Confirm at first device build.
- **Risk + fallback**: the Android Dart-native-assets path is the newest mechanism. If the first Android/iOS build hits native-assets friction, switch to **`pdfx 2.9.2`** (`sdk >=3.3.0, flutter >=3.24.0`, platform-views/texture, mature) with the same on-device PDFium guarantee. The viewer is isolated behind one page widget, so the swap is local.

### video_thumbnail_plus `^0.0.2`
- **environment**: `sdk >=2.12.0 <4.0.0`, `flutter >=2.0.0` → ✓.
- **Min OS**: iOS 13, Android API 24 → within floor.
- **Native**: AVFoundation (iOS) / MediaMetadataRetriever (Android). For our **received files in the app sandbox** no photo-library permission is needed (the "Videos from Photo Library require permissions" note applies to gallery URIs, which we don't use).
- **Maturity risk**: `0.0.2`, unverified uploader. Mitigated by FR-013's mandatory graceful fallback — a failed/empty thumbnail degrades to the existing play-glyph placeholder, so a flaky generator never breaks the grid. Generation is wrapped in `Result<T>`; output is disk-cached so each video is decoded at most once.
- **Rejected**: `video_thumbnail 0.5.6` (incompatible upper bound `<3.0.0`).

### Rejected / not needed
- **`photo_view`** (0.15.0) — compatible but unnecessary; `InteractiveViewer` meets FR-005.
- **`chewie`** (1.14.1) — video-centric controls UI; we need one set of controls spanning video + audio, so a small custom controls widget is simpler (YAGNI).
- **`media_kit`** (1.2.6) — full libmpv stack; powerful but heavy native footprint, unjustified when `video_player` covers FR-006/007.
- **`syncfusion_flutter_pdfviewer`** — heavy + commercial-license considerations; `pdfrx` (MIT, PDFium) is lighter and on-device.

---

## Resolved clarifications (from `/speckit.clarify`, Session 2026-06-29)

1. **Sent vs received**: only **received** files open an in-app viewer; **sent** files always use the existing OS open/share fallback (sent source paths are temporary/security-scoped). → coordinator gates on direction (FR-001).
2. **Thumbnail cache**: **disk-persisted across sessions**, keyed by `path + mtime`, size-bounded with LRU eviction; decode once per video (FR-013a).
3. **Large text**: cap ≈1 MB; show leading portion truncated + notice + open/share (FR-010a).

## Resolved deferred details (plan-time decisions)

- **Text/code allowlist** (FR-010): mime `text/*` OR extension ∈ {`txt, md, markdown, json, xml, csv, tsv, log, yaml, yml, ini, conf, toml, html, htm, css, js, ts, dart, py, java, kt, swift, c, h, cpp, hpp, cs, go, rb, php, sh, bash, sql, gradle, properties`}. Anything else in the `files` bucket → unsupported → fallback. Final list lives in one core constant.
- **Text cap value**: **1 MiB** read cap (`1 << 20` bytes); larger → truncated-with-notice. Exact constant in `core/constants`.
- **Thumbnail cache size**: bound the on-disk cache to **~64 MB** (LRU); thumbnails are small JPEGs (~240px). Decode width capped (`maxWidth ≈ 320`).
- **HEIC/HEIF**: routed to the image viewer; iOS decodes natively, Android decode is best-effort — a decode failure falls to the image error state + open/share (FR-015). No special handling.
- **GIF**: shown via `Image.file` which animates GIFs natively — acceptable; no extra work.
- **Image OOM guard**: the full-screen image viewer decodes with a screen-bounded `cacheWidth` (not unbounded) so a very large image cannot OOM (FR-018).

---

## Architecture decisions

- **New feature module `features/viewers/`** (Constitution XI): owns the viewer pages + cubits. Reuses core services; imports no other feature.
- **Launch seam is core-pure, not cross-feature**: a `core/presentation/viewers/` coordinator function `openTransferredFile(context, …)` resolves the viewer kind, applies the received-only + exists gate, and either `context.push(AppRoutes.fileViewer, extra: ViewerRequest)` or falls back to `ReceivedFilesService.open`/share. It imports core router constants + `ReceivedFilesService` only — **never a feature page** (the router binds the page). The three entry points (History detail, Receive-complete, Home/See-all) all call this one function → identical behavior (FR-003).
- **One dispatcher route** `AppRoutes.fileViewer` with a core-typed `ViewerRequest` extra; the page switches on `ViewerKind` to the right viewer widget. Pushed on the **root navigator** → full-screen, hides bottom nav (FR-020, Constitution X).
- **Viewer-kind resolution** is a core-pure `ViewerResolver.of(name, mime)` in `core/utils/` returning `ViewerKind { image, video, audio, pdf, text, unsupported }`. It supersedes `FileCategory` for *routing* (audio splits out of the `files` bucket; pdf/text split out) but reuses the same image/video extension sets to stay consistent with #012.
- **Video thumbnails**: a `@lazySingleton` `VideoThumbnailService` (interface in `core/services/media/`) wraps `video_thumbnail_plus` + a disk LRU cache (`path_provider` cache dir, key `path+mtime`). `MediaThumbnail` (#012, `core/presentation/media/`) gains a video branch that asynchronously requests a thumbnail and falls back to the play-glyph — so Home recent + See-all video tiles upgrade with no feature edits. (Scope note: FR-012 "History" = the media-grid surfaces; the History *detail* file list uses `FileRow` icons and is left as-is to avoid scope creep — recorded as an intentional bound.)
- **State (Principle III, 4-state freezed)**:
  - `MediaPlayerCubit` (`@injectable`) — drives the shared video/audio player over the `MediaController` seam; **releases the controller on close** (FR-008).
  - `TextViewerCubit` (`@injectable`) — reads up to the cap, emits `loaded(text, truncated)` or `error`.
  - PDF + image viewers are effectively stateless (pdfrx owns its controller; image is `InteractiveViewer`) — no cubit unless error-state handling warrants a tiny one; keep minimal.
- **Errors (Principle V)**: reuse existing `AppFailure.fileReadFailed` / `unknown` for corrupt/unreadable; no new `AppFailure` variant (YAGNI). "File unavailable" and "unsupported→fallback" are coordinator-level outcomes, not failures.
- **No engine/signaling/transport/protocol/DB-schema edits** — additive only, consistent with the spec.

## Open items for tasks/plan
- Confirm pdfrx first-build on iOS (pod) + Android (native assets); keep `pdfx` fallback noted.
- Decide whether a tiny `PdfViewerCubit` is needed for the load-error state, or pdfrx's own error builder suffices (lean: use pdfrx's builder; no cubit).
