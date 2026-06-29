# Quickstart: In-App File Viewers (#013)

## Prerequisites
- Branch `013-in-app-viewers`, Dart 3.11.5 / Flutter 3.41.7.
- Add 3 packages (verified, research.md): `video_player ^2.11.1`, `pdfrx ^2.4.4`, `video_thumbnail_plus ^0.0.2`.

```bash
flutter pub add video_player pdfrx video_thumbnail_plus
dart run build_runner build --delete-conflicting-outputs   # freezed states + injectable
```

## Gates (Constitution — run before commit)
```bash
dart format .
dart analyze lib test          # 0 issues (flutter analyze crashes on this checkout — use dart analyze)
flutter test                   # all pass (≈318 prior + new)
# dart run bloc_tools:bloc lint .   # CLI still uninstalled (tracked since #001)
```

## Manual verification (on device — deferred task, local feature, no two-device smoke)
For each path, tap a **received** file from History detail, the Receive-complete list, and a Home/See-all grid; confirm identical behavior:

1. **Image** (jpg/png/heic): full-screen, pinch-zoom + pan, back returns to origin, share/open works.
2. **Video** (mp4/mov): player opens at first frame, play/pause, scrub, elapsed/total correct; back stops playback (no background audio).
3. **Audio** (mp3/m4a): same player, audio-only layout (no black box).
4. **PDF**: pages scroll/zoom; large PDF stays responsive.
5. **Text/code** (txt/json/dart): readable, selectable, monospace for code; a >1 MB text shows truncated + "open externally" notice.
6. **Unsupported** (docx/zip): falls back to OS open/share — no dead end, no regression.
7. **File unavailable**: delete a received file, tap its history row → clear "unavailable" state, no crash.
8. **Sent side**: tap a sent file in History → OS open/share fallback (no in-app viewer).
9. **Thumbnails**: Home/See-all video tiles show a real first frame (play glyph overlaid); scroll a long list → lazy, memory bounded; re-open app → thumbnails reappear from disk cache (no re-decode).
10. **Airplane mode**: all viewers still open on-disk files (proves on-device, SC-008).

## Native build notes
- First `pod install` since #011 — adds `video_player_avfoundation`, pdfrx/PDFium XCFramework, and the thumbnail pod (expect `ios/Podfile.lock` churn; commit it).
- pdfrx Android bundles PDFium via Dart native assets; if the first Android/iOS build hits native-assets friction, swap to the documented fallback `pdfx 2.9.2` (viewer is isolated to one page).
- No new permissions / Info.plist keys (local sandbox files only).
