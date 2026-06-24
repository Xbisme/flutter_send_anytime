# Implementation Plan: Project Foundation & Navigation

**Branch**: `001-project-foundation` | **Date**: 2026-06-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-project-foundation/spec.md`

## Summary

Stand up the Safe Send Flutter application shell on iOS + Android: a fixed light/dark design-token system (Sora + JetBrains Mono, brand-green semantic palette), a reusable widget library, a minimal static branded splash, a 3-tab bottom navigation (Trang chủ / Lịch sử / Cài đặt) via `go_router` `StatefulShellRoute`, and a fully laid-out Home screen with **static sample/mock data** matching the design — including tappable **Gửi/Nhận** actions that push nav-less "coming soon" placeholder flows. No networking, WebRTC, persistence, or real settings logic. Architecture follows Clean Architecture + feature-first per the constitution; foundation primitives (`Result<T>`, `AppFailure`, `AppCubit<T>`, `AppLogger`, `AppToast`) and DI (`get_it` + `injectable`) are established for every later spec to build on. l10n ships Vietnamese-primary + English, with Vietnamese as the fallback for other device languages.

## Technical Context

**Language/Version**: Dart (latest stable, SDK `>=3.5.0`) / Flutter (latest stable 3.x)
**Primary Dependencies** (latest stable verified on pub.dev 2026-06-24):
- State: `flutter_bloc` 9.1.1 (+ `bloc` 9.2.1), test `bloc_test` 10.0.0
- DI: `get_it` 9.2.1, `injectable` 3.0.0 (+ `injectable_generator` 3.1.0)
- Router: `go_router` 17.3.0
- Codegen: `freezed` 3.2.5 (+ `freezed_annotation` 3.1.0), `json_serializable` 6.14.0 (+ `json_annotation` 4.12.0), `build_runner` 2.15.0
- UI: `lucide_icons_flutter` 3.1.14+2 (Lucide set), `flutter_svg` 2.3.0 (brand marks), `toastification` 3.2.0 (AppToast)
- Splash: `flutter_native_splash` 2.4.8 (dev-time generator → native static splash)
- i18n: `flutter_localizations` (SDK) + `intl` 0.20.2 + Flutter ARB
- Lint: `very_good_analysis` 10.3.0 (+ `bloc_lint` via `bloc_tools`)
- Test: `flutter_test` (SDK), `mocktail` 1.0.5
- **Fonts bundled as assets** (Sora, JetBrains Mono) — no `google_fonts` runtime dependency (offline-first, Constitution XIII)

**Storage**: N/A this feature (no persistence; `drift` deferred to #006)
**Testing**: `flutter_test` (widget), `bloc_test` (cubits), `mocktail` (mocks); `very_good test --test-randomize-ordering-seed random`
**Target Platform**: iOS 13.0+ and Android 8.0 (API 26)+ (per spec clarification)
**Project Type**: Mobile app (Flutter, single codebase, iOS + Android)
**Performance Goals**: 60 fps scroll on the Home screen; cold-start to first interactive Home frame within typical Flutter budgets; no jank on tab switches
**Constraints**: Fully offline (no network this spec); fixed light/dark palette only (no scheme picker); Reduce Motion → static; Dynamic Type / font-scaling adaptive; content within safe area on notch/Dynamic Island + display cutouts; zero `flutter analyze` warnings; zero `bloc_lint` violations
**Scale/Scope**: ~6 screens (splash, Home, History placeholder, Settings placeholder, Send placeholder flow, Receive placeholder flow); ~10 shared components; 2 flavors (dev/prod); EN + VI ARB

**Resolved unknowns** (were candidate NEEDS CLARIFICATION → settled in research.md):
- Icon package → `lucide_icons_flutter` (R-01)
- Font delivery → bundled TTF assets, not `google_fonts` (R-02)
- Splash approach → `flutter_native_splash` static (R-03)
- Bundle identifiers + flavor strategy → `app.safesend` (prod) / `app.safesend.dev` (dev) (R-04, user-confirmable)
- Freezed 3.x sealed-class state pattern (R-05)
- Theme-mode source in #001 → device/system only, no in-app toggle (R-06)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Constitution v1.0.0 (15 principles). Relevance for a no-network foundation spec:

| # | Principle | Applies to #001? | Compliance approach | Gate |
|---|---|---|---|---|
| I | Privacy-First P2P | Partial (logging only) | `AppLogger` only; no sensitive data exists yet; no networking | ✅ PASS |
| II | Direct Transfer & Data Min. | No | No transfer in scope | ✅ N/A |
| III | BLoC 4-state | Yes | All cubits (Home, AppShell, placeholder flows) use freezed 4-state; Use Cases injected, not repos; page-scoped providers | ✅ PASS |
| IV | Code Quality & Dart Safety | Yes | `very_good_analysis` zero-warning; strict casts/raw-types/inference; freezed immutable state; explicit types | ✅ PASS |
| V | Result\<T\> Error Handling | Yes (scaffold) | `Result<T>` + `AppFailure` established; placeholder data source returns `Result`; no try/catch in cubits | ✅ PASS |
| VI | Design System & Theming | Yes (core deliverable) | This spec BUILDS the fixed token system + shared factories; semantic tokens only, no hardcoded hex; CTA pill convention | ✅ PASS |
| VII | Cross-Platform Native | Yes | iOS + Android; Cupertino/Material affordances where relevant; safe-area; min iOS 13 / Android 26 | ✅ PASS |
| VIII | Transport & Signaling | No | Deferred to #002/#003; `safesend://` scheme reserved only | ✅ N/A |
| IX | Transfer Reliability | No | Deferred | ✅ N/A |
| X | go_router Navigation | Yes | `StatefulShellRoute.indexedStack` (3 tabs); `AppRoutes` constants; flows hide nav; deep-link scheme reserved | ✅ PASS |
| XI | Feature-First Modularity | Yes | `core/` + `features/{splash,home,send,receive,history,settings}`; core MUST NOT import features; `@lazySingleton`/`@injectable` only | ✅ PASS |
| XII | Testing Discipline | Yes | Widget tests for shell screens; bloc tests for cubits; no two-device gate (no transfer) | ✅ PASS |
| XIII | Simplicity & YAGNI | Yes | No persistence/networking/abstractions beyond need; fonts bundled vs extra dep; placeholder flows are stubs | ✅ PASS |
| XIV | i18n by Default | Yes | All strings in ARB; `context.l10n`; VI primary + EN; VI fallback; `intl` formatters | ✅ PASS |
| XV | Dependency Hygiene | Yes | All versions fetched from pub.dev at plan time (this file); caret constraints; no fictional packages | ✅ PASS |

**Result**: No violations. No entries in Complexity Tracking. Proceed to Phase 0.

**Post-Design re-check (after Phase 1)**: Still PASS — data-model + contracts introduce no new dependencies and keep `core/` free of `features/` imports; all UI models are presentation-layer mock view-models; no constitution deviation.

## Project Structure

### Documentation (this feature)

```text
specs/001-project-foundation/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── navigation-and-routes.md
│   ├── design-tokens.md
│   ├── shared-widgets.md
│   └── localization-keys.md
└── tasks.md             # Phase 2 output (/speckit-tasks — NOT created here)
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── app.dart                      # Root MaterialApp.router + theme + l10n wiring
│   └── view/                         # App-level shell scaffold (StatefulShellRoute shell w/ bottom nav)
├── bootstrap.dart                    # Pre-runApp setup (DI init, error zone, AppLogger)
├── main_dev.dart                     # Dev flavor entry
├── main_prod.dart                    # Prod flavor entry
├── core/
│   ├── config/                       # AppConfig, AppFlavor (dev/prod), build constants
│   ├── constants/                    # AppRoutes, asset keys, deep-link scheme (safesend://)
│   ├── di/                           # injectable graph (get_it) + @InjectableInit
│   ├── domain/                       # Result<T>, AppFailure (freezed), AppCubit<T> base
│   ├── presentation/                 # SHARED WIDGET LIBRARY (the design-system components)
│   │   ├── buttons/                  #   PrimaryButton / SecondaryButton / DangerButton
│   │   ├── files/                    #   FileChip, FileRow
│   │   ├── inputs/                   #   CodeBox, SegmentedTabs, ToggleRow, SearchPill
│   │   ├── tiles/                    #   StatTile, QuickActionCard
│   │   ├── feedback/                 #   AppToast, AppEmptyView
│   │   └── scaffolding/              #   FlowAppBar, ComingSoonView
│   ├── theme/                        # AppColors (light+dark), AppTypography, AppSpacing/Radii/Shadow/Motion, AppTheme
│   └── utils/                        # AppLogger, formatters (size/number/date)
├── features/
│   ├── splash/presentation/          # Splash screen (static branded)
│   ├── home/                         # Home tab: page + HomeCubit + placeholder view-models + section widgets
│   │   ├── domain/                   #   Home placeholder data source interface + mock models
│   │   ├── data/                     #   Static mock data source (returns Result)
│   │   └── presentation/             #   HomePage, HomeCubit, section widgets, action entry points
│   ├── send/presentation/            # Send placeholder flow (ComingSoonView, nav-less)
│   ├── receive/presentation/         # Receive placeholder flow (ComingSoonView, nav-less)
│   ├── history/presentation/         # History tab placeholder (title + empty state)
│   ├── settings/presentation/        # Settings tab placeholder (profile card + static toggle rows + version)
│   └── (pairing/ — NOT created in #001; first built in #003)
# Note: features/pairing/ appears in the project-context repo map as the eventual
# Connect hub; it is intentionally OUT OF SCOPE for #001 and must not be created here.
└── l10n/
    ├── arb/app_en.arb
    └── arb/app_vi.arb                # Vietnamese primary

assets/
├── brand/                            # logomark.svg, logo-wordmark.svg (from claude_design)
└── fonts/                            # Sora-*.ttf, JetBrainsMono-*.ttf

test/
├── core/                             # theme tokens, shared widgets, Result/AppFailure, formatters
└── features/                         # home (cubit + page), shell navigation, splash, placeholders

# Native (generated by `flutter create`, then configured):
ios/      # min iOS 13.0, flavor schemes/xcconfig (dev/prod), display name, splash, safe-area
android/  # minSdk 26, productFlavors (dev/prod), app label, splash
```

**Structure Decision**: Single Flutter mobile project (Clean Architecture + feature-first). The **shared widget library lives in `core/presentation/`** (not in a feature) because it is consumed by every feature and `core/` must never import `features/` (Constitution XI). Each tab and each placeholder flow is its own feature folder so #004/#005/#006/#010 can replace the placeholder presentation in-place without touching the shell. `app/` holds only the root app + the `StatefulShellRoute` scaffold that hosts the bottom navigation.

## Complexity Tracking

> No constitution violations — section intentionally empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
