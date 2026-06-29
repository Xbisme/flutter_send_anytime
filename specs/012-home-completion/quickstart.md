# Quickstart: Home Screen Completion (#012)

Additive, feature-local rework of Home over the #006 history store. **No new packages.**

## Prerequisites
- Branch `012-home-completion`.
- #006 history store present (it is; `TransferHistoryRepository` + drift in `core/`).
- Toolchain note: use `dart analyze lib test` (not `flutter analyze`).

## Build order (suggested)

1. **DesignSync (R7)** — `/design-login` then pull the updated **Home** + new **See-all** screens from claude_design `SafeSend`; distil into `.claude/claude-app/ui-design-context.md` (§Screen 01 + new See-all section). Confirm preview caps + video-tile/thumbnail treatment against the render.
2. **Core helpers** — `core/utils/file_category.dart` (`MediaCategory` + `FileCategory.of`); `core/presentation/media/media_thumbnail.dart` (real `Image.file` with `cacheWidth`, else type icon). Unit-test categorization.
3. **Domain** — extend `home_dashboard.dart` (media items gain `category`/`record`/`localPath`; `MediaCategory`); add `HomeDashboardBuilder` (pure) + `WatchHomeDashboardUseCase` + `WatchMediaItemsUseCase`. Unit-test the builder (summary/stats/categorization/recency/empty).
4. **HomeCubit** — make reactive (StreamSubscription, emit `loaded` per snapshot, cancel on close); remove `HomePlaceholderDataSource`. bloc_test load + live-update + empty + error.
5. **Home UI** — wire real media + `MediaThumbnail` into `home_sections.dart`; section empty states; "Xem tất cả" → `context.push(homeSeeAll, extra: category)`; item tap → `historyDetail`. Widget-test real data + empty + taps.
6. **See-all** — `AppRoutes.homeSeeAll` + `GoRoute` (root nav); `SeeAllCubit`; `SeeAllPage` (lazy grid/list, reuse cells); empty state; tap → detail. bloc_test + widget test.
7. **i18n** — add ARB (VI primary + EN, `@description`): stat labels, section titles, See-all titles, empty-state copy, file-unavailable message. Keep VI/EN key parity.
8. **Gates** — `dart analyze lib test` = 0 · `flutter test` all pass · `dart format --set-exit-if-changed .` clean · (bloc lint when CLI available).

## Manual verification (simulator/device)
- Fresh install (no history) → hero zeros, all sections + See-all show empty states; no mock content (SC-002).
- Do a few sends/receives of mixed types → Home hero totals + monthly count + stat counts match (SC-001); recent sections show real items newest-first; received images show real thumbnails, sent/missing show type icons (FR-006/006a).
- Complete a transfer while on another tab → return to Home shows it without restart (SC-003 / FR-011); delete a record in History → Home updates.
- Tap a recent item → opens its History detail with Open/Share (FR-007). Open an item whose file was deleted → graceful message, no crash (FR-014).
- "Xem tất cả" on each section → full list, scrolls smoothly over a large history, back returns to Home (SC-004/SC-006).

## Out of scope (defer)
- In-app media preview/playback → #013.
- Real video-frame thumbnails (would need a native plugin) → #013.
- On-device media-library indexing / new permissions (FR-016 = history only).
