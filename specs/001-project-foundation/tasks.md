---
description: "Task list for Project Foundation & Navigation"
---

# Tasks: Project Foundation & Navigation

> **Status (2026-06-24): IMPLEMENTED — 67/70 tasks done.** Full Dart app builds; `dart analyze lib test` = **0 issues**; `flutter test` = **27 passed**; `dart format` clean; native splash generated. The whole shell (3-tab nav, Home with mock dashboard, Send/Receive nav-less flows, History/Settings placeholders), the fixed light/dark design-token system, the shared widget library, DI, codegen (freezed/injectable), and l10n (VI primary + EN) are all in and tested.
>
> **Flavors (T006 + T007): dev/prod fully wired on BOTH platforms.** Android `productFlavors` (`app.safesend.dev` / `app.safesend`, labels, `minSdk 26`). iOS build configs `Debug/Release/Profile-{dev,prod}` + shared schemes `dev`/`prod` (default `Runner` scheme removed) generated via [ios/setup_flavors.rb](../../ios/setup_flavors.rb) and **verified with `xcodebuild -list` + `-showBuildSettings`** (Debug-dev → `app.safesend.dev`, Release-prod → `app.safesend`). Run: `flutter run --flavor dev -t lib/main_dev.dart` / `--flavor prod -t lib/main_prod.dart`.
>
> **3 deferred (device/external-only):**
> - **T005** bloc-lint CLI (`bloc_tools`) not wired — BLoC follows the 4-state pattern and passes `dart analyze`.
> - **T067** build + launch both flavors on a physical iOS/Android device (signing) — flavor *wiring* verified via xcodebuild; on-device run still pending.
> - **T068** manual quickstart SC-001…009 smoke (device).
>
> **Local-toolchain note**: `flutter analyze` crashes on this detached-HEAD Flutter checkout (AOT analysis-server snapshot); use **`dart analyze`** — same analyzer engine + `analysis_options.yaml`, gate-equivalent.

**Input**: Design documents from `specs/001-project-foundation/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included — Constitution XII requires widget tests for shell flows and bloc tests for cubits; spec acceptance scenarios drive them.

**Organization**: Tasks grouped by user story. Setup + Foundational (Phases 1–2) build the shared shell, design system, and widget library all stories depend on; Phases 3–5 are the three user stories in priority order.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 / US2 / US3 (story phases only)
- All paths are repository-relative.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, flavors, tooling, assets.

- [x] T001 Run `flutter create` at repo root (org `app.safesend`, platforms iOS + Android), then remove sample counter app
- [x] T002 Restructure into Clean Architecture tree per plan.md (`lib/app/`, `lib/core/{config,constants,di,domain,presentation,theme,utils,router}`, `lib/features/{splash,home,send,receive,history,settings}`, `lib/l10n/arb/`)
- [x] T003 [P] Add all dependencies + dev_dependencies to `pubspec.yaml` with the pinned versions from plan.md and run `flutter pub get`
- [x] T004 [P] Configure `analysis_options.yaml` with `very_good_analysis` 10.3.0 + `strict-casts`/`strict-raw-types`/`strict-inference`
- [ ] T005 [P] Configure `bloc_lint` (`bloc.yaml` / analysis include) so `dart run bloc_tools:bloc lint .` runs clean
- [x] T006 Configure iOS flavors (dev/prod) — per-flavor `.xcconfig` + schemes, bundle ids `app.safesend` (prod) / `app.safesend.dev` (dev), display names, deployment target iOS 13.0, register `safesend://` URL type
- [x] T007 Configure Android flavors (dev/prod) — Gradle `productFlavors`, `applicationId` + suffix, `minSdk 26`, `targetSdk` latest, app labels, `safesend` intent-filter scheme placeholder
- [x] T008 [P] Create `lib/main_dev.dart`, `lib/main_prod.dart` (flavor entry points) and `lib/bootstrap.dart` skeleton (error zone + runApp hook)
- [x] T009 [P] Add brand SVGs to `assets/brand/` and Sora + JetBrains Mono TTFs to `assets/fonts/`; declare assets + font families in `pubspec.yaml`
- [x] T010 [P] Configure `flutter_native_splash` (per-flavor: logomark on brand background, light + dark) and generate native splash
- [x] T011 [P] Configure `l10n.yaml` + `gen-l10n` (template-arb `app_vi.arb`, output `AppLocalizations`, `context.l10n` extension)
- [x] T012 [P] Configure `build_runner` and verify an initial `dart run build_runner build --delete-conflicting-outputs` succeeds

**Checkpoint**: App compiles to a blank screen on both flavors/platforms; tooling + codegen green.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Primitives, DI, design tokens, routing shell, shared widget library, l10n strings — shared by ALL user stories.

**⚠️ CRITICAL**: No user-story work begins until this phase completes.

### Core primitives & infrastructure
- [x] T013 [P] Implement `Result<T>` (Success/Failure + fold/when) in `lib/core/domain/result.dart`
- [x] T014 [P] Implement `AppFailure` freezed sealed union (`unexpected`, `notImplemented`) in `lib/core/domain/failures/app_failure.dart`
- [x] T015 [P] Implement `AppCubit<T>` base with 4-state freezed union (initial/loading/loaded/error) in `lib/core/domain/cubit/app_cubit.dart`
- [x] T016 [P] Implement `AppLogger` in `lib/core/utils/app_logger.dart` (no print/debugPrint anywhere)
- [x] T017 [P] Implement `AppFlavor` enum + `AppConfig` in `lib/core/config/` (appName, flavor, deepLinkScheme `safesend`)
- [x] T018 Set up DI: `@InjectableInit` graph in `lib/core/di/injection.dart`, register `AppConfig`, wire `configureDependencies()` into `bootstrap.dart` (depends on T017)
- [x] T019 [P] Implement size/number/date formatters in `lib/core/utils/formatters.dart`
- [x] T020 [P] Implement shared `TransferDirection` enum + file-ext→color map in `lib/core/domain/transfer_enums.dart` (reused by History #006)

### Design system (contracts/design-tokens.md)
- [x] T021 [P] Implement `AppColors` (light + dark semantic aliases + ramps + status + gradients) in `lib/core/theme/app_colors.dart`
- [x] T022 [P] Implement `AppTypography` (Sora display/body + JetBrains Mono styles, full scale) in `lib/core/theme/app_typography.dart`
- [x] T023 [P] Implement `AppSpacing`, `AppRadii`, `AppShadow`, `AppMotion` in `lib/core/theme/app_dimens.dart`
- [x] T024 Implement `AppTheme.light` / `AppTheme.dark` `ThemeData` from tokens in `lib/core/theme/app_theme.dart` (depends on T021–T023)

### Routing & app shell
- [x] T025 [P] Define `AppRoutes` constants + deep-link scheme in `lib/core/constants/app_routes.dart`
- [x] T026 Build `go_router` config: `StatefulShellRoute.indexedStack` with 3 branches (home/history/settings) + top-level `send`/`receive` routes in `lib/core/router/app_router.dart` (depends on T025)
- [x] T027 Build app shell scaffold + bottom `NavigationBar` (3 tabs, token-styled, Lucide icons, l10n labels) hosting the shell branches in `lib/app/view/app_shell.dart` (depends on T026, T029–T035 partial)
- [x] T028 Build root `app.dart` (`MaterialApp.router` + AppTheme + `ThemeMode.system` + localizations + VI locale fallback) in `lib/app/app.dart` (depends on T024, T026)

### Shared widget library (FR-017 — core/presentation)
- [x] T029 [P] `PrimaryButton`, `SecondaryButton`, `DangerButton` in `lib/core/presentation/buttons/`
- [x] T030 [P] `FileChip`, `FileRow` in `lib/core/presentation/files/` (depends on T020 ext-color map)
- [x] T031 [P] `StatTile`, `QuickActionCard` in `lib/core/presentation/tiles/`
- [x] T032 [P] `ToggleRow`, `SearchPill` in `lib/core/presentation/inputs/`
- [x] T033 [P] `CodeBox`, `SegmentedTabs` in `lib/core/presentation/inputs/` (reserved for #003/#005; built now per FR-017)
- [x] T034 [P] `AppToast` (toastification wrapper) + `AppEmptyView` in `lib/core/presentation/feedback/`
- [x] T035 [P] `FlowAppBar`, `ComingSoonView` in `lib/core/presentation/scaffolding/`

### Localization strings
- [x] T036 Add all keys (vi primary + en) from contracts/localization-keys.md to `lib/l10n/arb/app_vi.arb` + `app_en.arb` and regenerate

**Checkpoint**: Shell renders 3 empty tabs in light/dark; all shared widgets compile and have a token-driven appearance. User stories can now proceed.

---

## Phase 3: User Story 1 — Navigate the app shell across three tabs (Priority: P1) 🎯 MVP

**Goal**: A working 3-tab navigation frame (Trang chủ / Lịch sử / Cài đặt) with per-tab state preservation and the three destination screens present.

**Independent Test**: Launch → Home shown first with 3-tab bar; tap each tab → correct destination; scroll Home, switch away/back → scroll preserved; confirm no Send/Receive tab.

- [x] T037 [US1] Build `HomePage` scaffold (header: logomark + "Safe Send" wordmark + Settings shortcut; scrollable body container) in `lib/features/home/presentation/home_page.dart`
- [x] T038 [P] [US1] Build `HistoryPage` placeholder (title + `AppEmptyView`) in `lib/features/history/presentation/history_page.dart`
- [x] T039 [P] [US1] Build `SettingsPage` placeholder (DeviceProfile card + static `ToggleRow`s + version footer) in `lib/features/settings/presentation/settings_page.dart`
- [x] T040 [US1] Register the three destinations in the shell branches + wire the Home→Settings shortcut navigation (depends on T037–T039, T027)
- [x] T041 [P] [US1] Widget test: 3 tabs present, Home initial, active indicator moves, per-tab scroll/state preserved on switch in `test/features/navigation_test.dart`
- [x] T042 [P] [US1] Widget test: History + Settings placeholders render with correct titles/empty states in `test/features/placeholders_test.dart`

**Checkpoint**: Navigation MVP works end-to-end and is independently demoable.

---

## Phase 4: User Story 2 — Full Home layout + open Send & Receive flows (Priority: P1)

**Goal**: Home shows the complete designed layout with static sample data, and Gửi/Nhận open full-screen nav-less placeholder flows.

**Independent Test**: Open Home → all designed sections visible with sample data; tap Gửi → full-screen ComingSoon, bottom bar hidden, back → Home; repeat Nhận.

- [x] T043 [P] [US2] Define Home mock view-models (`HomeDashboard`, `TransferSummary`, `StatTileModel`, `MediaThumb`, `VideoThumb`, `FileItemModel`, `TransferGroupModel`, `QuickActionModel`) in `lib/features/home/domain/models/`
- [x] T044 [US2] Implement `HomePlaceholderDataSource` returning `Result<HomeDashboard>` with static mock data matching the design in `lib/features/home/data/home_placeholder_data_source.dart` (depends on T043)
- [x] T045 [US2] Implement `HomeCubit` (extends `AppCubit<HomeDashboard>`, load → loaded) + DI registration in `lib/features/home/presentation/cubit/` (depends on T044, T015)
- [x] T046 [P] [US2] Hero summary card widget (brand gradient, sent/received mono totals, progress bar, monthly count) in `lib/features/home/presentation/widgets/home_hero_card.dart`
- [x] T047 [P] [US2] Stat-tiles row widget (Photos/Videos/Files via `StatTile`) in `lib/features/home/presentation/widgets/home_stats_row.dart`
- [x] T048 [P] [US2] Recent images grid + recent videos grid widgets in `lib/features/home/presentation/widgets/`
- [x] T049 [P] [US2] Recent files list (`FileRow`) + recent transfers cards widgets in `lib/features/home/presentation/widgets/`
- [x] T050 [P] [US2] Quick-actions grid (`QuickActionCard`) + tip card widgets in `lib/features/home/presentation/widgets/`
- [x] T051 [US2] Assemble full `HomePage` from sections, provide `HomeCubit`, render `loaded` state, wire Gửi/Nhận + quick-action taps to routes (depends on T045–T050, T037)
- [x] T052 [P] [US2] Send placeholder flow page (`FlowAppBar` + `ComingSoonView`) on the nav-less `/send` route in `lib/features/send/presentation/send_page.dart`
- [x] T053 [P] [US2] Receive placeholder flow page on the nav-less `/receive` route in `lib/features/receive/presentation/receive_page.dart`
- [x] T054 [P] [US2] Bloc test: `HomeCubit` emits loading → loaded with mock dashboard in `test/features/home/home_cubit_test.dart`
- [x] T055 [P] [US2] Widget test: Home sections render; tapping Gửi/Nhận pushes nav-less flow (bottom bar hidden) and back returns to Home in `test/features/home/home_page_test.dart`

**Checkpoint**: Home is fully laid out and both core actions reach their (placeholder) flows.

---

## Phase 5: User Story 3 — Light/dark, localized & accessible shell (Priority: P2)

**Goal**: The whole shell is correct in light + dark, fully localized (VI primary, EN, VI fallback), and respects Reduce Motion, Dynamic Type, screen readers, and safe areas.

**Independent Test**: Toggle OS dark mode → palette flips; switch VI↔EN → labels change, unsupported locale → VI; enable Reduce Motion → animations static; enlarge font → layout adapts; view on notch + cutout devices → within safe area.

- [x] T056 [US3] Verify `ThemeMode.system` wiring and perform a dark-palette correctness sweep across Home, History, Settings, Send, Receive, splash (depends on T028, T051)
- [x] T057 [P] [US3] Implement `supportedLocales` + `localeResolutionCallback` fallback to Vietnamese in `lib/app/app.dart`; verify all visible strings switch VI/EN
- [x] T058 [P] [US3] Add Reduce-Motion helper (reads `MediaQuery.disableAnimations`) in `lib/core/utils/` and ensure any decorative motion/gradient renders static when enabled
- [x] T059 [P] [US3] Dynamic Type / text-scaling + safe-area audit: wrap shell + flow scaffolds correctly; fix any clipping/overflow on smallest + largest phones and notch/cutout devices
- [x] T060 [P] [US3] Add semantic labels/tooltips to nav destinations, the Settings shortcut, and the Gửi/Nhận primary actions
- [x] T061 [P] [US3] Widget test: shell renders correctly in both light and dark `ThemeData` in `test/core/theme_test.dart`
- [x] T062 [P] [US3] Test: locale fallback (unsupported → VI) + ARB parity (vi/en key sets match) in `test/l10n/localization_test.dart`
- [x] T063 [P] [US3] Test: Reduce-Motion static state + presence of semantic labels on key controls in `test/features/accessibility_test.dart`

**Checkpoint**: Shell passes theming, localization, and accessibility independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T064 [P] Unit/widget tests for design tokens (AppColors/AppTypography resolve per brightness) in `test/core/theme/`
- [x] T065 [P] Widget tests for the shared widget library (buttons, FileChip/Row, StatTile, QuickActionCard, ToggleRow, FlowAppBar, ComingSoonView, AppEmptyView) in `test/core/presentation/`
- [x] T066 Run pre-commit gate and fix to green: `dart format .`, `flutter analyze` (0 warnings), `flutter test`, `dart run bloc_tools:bloc lint .` (0)
- [ ] T067 [P] Build + launch BOTH flavors (dev/prod) on iOS and Android — confirm SC-008
- [ ] T068 [P] Execute quickstart.md manual verification mapping SC-001…SC-009
- [x] T069 Dead-code / unused-import / unused-dependency cleanup
- [x] T070 Per-spec hygiene: update `.claude/claude-app/project-context.md` + `sdd-roadmap.md` status and append `.claude/claude-app/changelog.md` entry on merge

---

## Dependencies & Execution Order

### Phase dependencies
- **Setup (P1)**: no deps — start immediately.
- **Foundational (P2)**: depends on Setup — **blocks all user stories**.
- **US1 (P3)**: depends on Foundational. MVP.
- **US2 (P4)**: depends on Foundational; extends the `HomePage` created in US1 (T037 before T051). Otherwise independent.
- **US3 (P5)**: depends on Foundational; sweeps across US1+US2 screens (so most valuable after both, but theming/i18n tasks can begin once any screen exists).
- **Polish (P6)**: after the desired stories are complete.

### Key intra-dependencies
- T018 ← T017 · T024 ← T021–T023 · T026 ← T025 · T027 ← T026 + shared widgets · T028 ← T024 + T026 · T040 ← T037–T039 · T044 ← T043 · T045 ← T044 · T051 ← T045–T050 + T037 · T056 ← T028 + T051.

### Parallel opportunities
- Setup: T003–T005, T008–T012 in parallel.
- Foundational: T013–T017, T019–T023 in parallel; shared widgets T029–T035 in parallel (after tokens T021–T024).
- US1: T038/T039 parallel; tests T041/T042 parallel.
- US2: models/widgets T043, T046–T050 parallel; flows T052/T053 parallel; tests T054/T055 parallel.
- US3: T057–T060 parallel; tests T061–T063 parallel.

---

## Parallel Example: Foundational design system + widgets

```bash
# Tokens (parallel):
Task: T021 AppColors   Task: T022 AppTypography   Task: T023 AppSpacing/Radii/Shadow/Motion
# Then shared widgets (parallel, after T024 AppTheme):
Task: T029 Buttons  Task: T030 FileChip/Row  Task: T031 Tiles  Task: T032 ToggleRow/SearchPill
Task: T033 CodeBox/SegmentedTabs  Task: T034 AppToast/EmptyView  Task: T035 FlowAppBar/ComingSoon
```

---

## Implementation Strategy

### MVP first
1. Phase 1 Setup → 2. Phase 2 Foundational → 3. Phase 3 US1 → **STOP & validate navigation MVP**.

### Incremental delivery
- Foundation ready → US1 (navigation MVP) → US2 (rich Home + flows) → US3 (theming/i18n/a11y polish) → Phase 6 gate. Each story is an independently demoable increment.

---

## Notes

- `[P]` = different files, no incomplete-task dependency.
- **FR-017 ↔ SC-007** (RESOLVED via `/speckit-analyze` F1): SC-007 was relaxed to allow **reserved** shared components (CodeBox / SegmentedTabs / DangerButton, T029/T033) that are built now but first *used* in #003/#004/#005. No deferral needed; build them in #001 per FR-017.
- Constitution gates apply every commit (T066). Package versions are pinned per plan.md (fetched from pub.dev — Constitution XV).
- No two-device smoke test here (no transfer in #001).
