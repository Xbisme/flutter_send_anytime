# Phase 0 Research: Project Foundation & Navigation

**Feature**: 001-project-foundation · **Date**: 2026-06-24

All package versions verified against pub.dev on 2026-06-24 (Constitution XV).

---

## R-01 — Icon package for the Lucide set

- **Decision**: `lucide_icons_flutter` 3.1.14+2.
- **Rationale**: The Safe Send design draws its icons from the Lucide set (smartphone, arrow-up-right/down-left, qr-code, radar, send, download, history, settings, house, etc.). `lucide_icons_flutter` is actively maintained and tracks upstream Lucide releases, so the icon names in the design resolve directly. It exposes a single `LucideIcons.*` accessor consistent with the constitution's "one icon set" rule.
- **Alternatives considered**:
  - `lucide_icons` 0.257.0 — pinned to an older Lucide snapshot and less actively maintained; risks missing newer glyphs used in the design.
  - `flutter_lucide` 1.11.0 — viable but smaller adoption; no advantage over `lucide_icons_flutter`.
  - `hugeicons` — different visual language than the design; rejected.

## R-02 — Font delivery (Sora + JetBrains Mono)

- **Decision**: Bundle the TTF files as app assets and wire them via `pubspec.yaml` `fonts:` + `TextTheme`. Do **not** add `google_fonts`.
- **Rationale**: Safe Send is a transfer tool used in offline / poor-connectivity contexts; runtime font fetching (google_fonts default) risks a flash of fallback type or missing brand fonts offline. The palette/typography is fixed (Constitution VI), so bundling is deterministic and removes a dependency (Constitution XIII Simplicity). Sora + JetBrains Mono are OFL-licensed and redistributable.
- **Alternatives considered**:
  - `google_fonts` 8.1.0 with runtime fetch — offline risk, extra dependency.
  - `google_fonts` with asset bundling — works but still adds a dependency layer over plain `TextTheme`; no benefit for two fixed families.

## R-03 — Splash / launch screen

- **Decision**: `flutter_native_splash` 2.4.8 to generate a **static** native launch screen (logomark on brand background) for iOS + Android; configured per-flavor. No animated/in-app splash widget beyond the brief native screen.
- **Rationale**: Matches the spec clarification (minimal static branded splash, no animation, no logic). Native splash avoids a blank first frame and needs no Reduce-Motion handling. It is a dev-time generator (config in `pubspec`, run once) — no runtime dependency cost.
- **Alternatives considered**:
  - In-app Dart splash widget with a timer — adds logic/route the spec said to avoid; harder to make pixel-correct on first frame.
  - Animated logomark splash — explicitly rejected in spec clarification (more work + Reduce-Motion concerns).

## R-04 — Bundle identifiers & flavor strategy

- **Decision**: Two flavors, `dev` and `prod`.
  - prod application id: `app.safesend`
  - dev application id: `app.safesend.dev`
  - Display name: "Safe Send" (prod), "Safe Send Dev" (dev).
  - iOS: per-flavor `.xcconfig` (Cleartime-style) + schemes; Android: `productFlavors` in Gradle.
- **Rationale**: Distinct ids let dev + prod coexist on one device. `app.safesend` is a clean reverse-style identifier; final ownership/domain is the user's call and can be changed before store submission without architectural impact.
- **Status**: User-confirmable — not a blocker for the foundation. Flagged for confirmation before any store account setup.
- **Alternatives considered**: single flavor (rejected — constitution + roadmap require dev/prod separation); `com.safesend.app` (equivalent; chose the shorter `app.safesend`).

## R-05 — Freezed 3.x state & BLoC 4-state pattern

- **Decision**: Use `freezed` 3.2.5 sealed unions for all Cubit states, following the mandatory 4-state shape: `initial → loading → loaded({required T data}) → error({required AppFailure failure})`. Events (where Blocs are used) are plain sealed classes; Cubits are preferred for #001.
- **Rationale**: Freezed 3.x emits sealed classes natively (pattern-matchable with Dart 3 `switch`). The 4-state pattern is Constitution III. For #001 most screens are static, but `HomeCubit` loads placeholder data through a `Result`-returning source and emits `loaded`, exercising the pattern so later specs inherit a correct template.
- **Notes**: Freezed 3.x requires `sealed`/`abstract` annotations and updated syntax vs 2.x; no migration needed (greenfield). Generated files via `build_runner`.
- **Alternatives considered**: `equatable` hand-written states (rejected — more boilerplate, weaker exhaustiveness); `freezed` 2.x (older, not latest).

## R-06 — Theme-mode source in #001

- **Decision**: Theme follows the OS (`ThemeMode.system`) only; the app provides both light and dark `ThemeData` from the fixed token set. No in-app light/dark toggle in #001.
- **Rationale**: Spec FR-014 + clarifications: only light/dark/follow-system, with the manual control delivered by Settings (#010). Keeping #001 system-driven avoids introducing a persisted preference (no `shared_preferences` yet) and honors YAGNI.
- **Alternatives considered**: in-app toggle now (rejected — needs persistence + belongs to #010); manual `ThemeMode` cubit stub (deferred to #010).

## R-07 — Navigation: StatefulShellRoute + nav-less flows

- **Decision**: `go_router` 17.3.0 with `StatefulShellRoute.indexedStack` for the 3 tabs (each branch keeps its own `Navigator`/state). Send and Receive open as **top-level routes outside** the shell branches, so the bottom navigation is not rendered for them. `AppRoutes` holds all path constants; `safesend://` registered as a deep-link scheme placeholder (no handlers wired this spec).
- **Rationale**: `indexedStack` preserves per-tab scroll/state (FR-003, SC-009). Placing flows outside the shell is the idiomatic go_router way to hide the bottom bar. Constitution X compliance.
- **Alternatives considered**: Material `NavigationBar` + manual `IndexedStack` without go_router shell (rejected — loses deep-link + guard infrastructure later specs need); pushing flows inside a branch (rejected — bottom bar would remain visible).

## R-08 — Localization & Vietnamese-first fallback

- **Decision**: Flutter ARB (`gen-l10n`) with `app_vi.arb` + `app_en.arb`; `supportedLocales = [vi, en]`; `localeResolutionCallback` falls back to **Vietnamese** for unsupported device languages. `context.l10n` accessor; `intl` for size/number/date formatting.
- **Rationale**: Spec FR-023/024/025 + clarified VI fallback. Vietnamese is the primary product language; English is secondary. Bundled formatting is locale-aware.
- **Alternatives considered**: English default fallback (rejected — contradicts product's VI-first positioning); third-party i18n libs (rejected — Flutter's official ARB is constitutional default).

## R-09 — Placeholder data shape (Home)

- **Decision**: A `HomePlaceholderDataSource` in `features/home/data/` returns a `Result<HomeDashboard>` of **static mock view-models** matching the design mockup (hero totals "24.3 GB / 39.7 GB"-style sample, sample image/video/file/transfer lists, stat counts). Clearly marked as mock; consumed by `HomeCubit` → `loaded`.
- **Rationale**: Spec clarification chose static sample data matching the design. Routing it through a `Result`-returning source + cubit means #006 swaps the data source for the real (drift-backed) one without touching the UI or cubit contract.
- **Alternatives considered**: hardcoding mock data directly in widgets (rejected — #006 would have to rewrite widgets; violates the swap-in seam).

---

## Best-practices notes captured for implementation

- **Design tokens vs source CSS**: where the claude_design `spacing.css` says `radius:0` but the rendered screens use 16–22px soft radii, the **rendered screens win** (per `ui-design-context.md`). Encode the rendered values in `AppRadii`.
- **Numeric/technical text** (sizes, codes, rates, counts) uses the JetBrains Mono family with tabular figures (Constitution VI / FR-016).
- **Reduce Motion**: read `MediaQuery.disableAnimations`; decorative motion (none ship in #001 beyond potential gradient — keep static) must respect it (FR-019) — establish the helper now for later radar/spinner.
- **Safe area**: wrap shell + flow scaffolds in `SafeArea`/`MediaQuery.padding` correctly; verify notch + cutout (FR-022).
- **`core/` purity**: shared widgets in `core/presentation/` must not import anything from `features/`; lints/CI enforce.
