# Quickstart: Project Foundation & Navigation

**Feature**: 001-project-foundation

## Prerequisites
- Flutter (latest stable) + Dart 3.5+; Xcode (iOS 13+ SDK) + Android SDK (API 26+).
- Brand assets (`logomark.svg`, `logo-wordmark.svg`) and fonts (Sora, JetBrains Mono TTFs) available to drop into `assets/`.

## First-time setup (high level)
1. `flutter create` the app at repo root (org `app.safesend`), then restructure into the Clean Architecture tree from plan.md.
2. Add dependencies (versions pinned in plan.md / pubspec) and run `flutter pub get`.
3. Drop brand SVGs into `assets/brand/`, fonts into `assets/fonts/`; declare both in `pubspec.yaml`.
4. Configure flavors: iOS xcconfig + schemes (`dev`/`prod`), Android `productFlavors`; min iOS 13.0, Android `minSdk 26`.
5. Generate native splash: configure `flutter_native_splash` (logomark on brand bg, per-flavor) and run it.
6. Wire `gen-l10n` (`l10n.yaml`, ARBs), `injectable` codegen, `freezed`/`json` codegen via `build_runner`.

## Daily commands
```bash
flutter run --flavor dev -t lib/main_dev.dart        # run dev
dart run build_runner build --delete-conflicting-outputs   # codegen (freezed/injectable/json)
flutter gen-l10n                                     # regenerate localizations

# Pre-commit gate (Constitution / dev-workflow):
dart format .
flutter analyze                  # zero warnings
flutter test                     # all pass
dart run bloc_tools:bloc lint .  # zero violations
```

## Manual verification (maps to Success Criteria)
1. **Launch** → splash → Home with 3-tab bar, Home active. (SC-001)
2. **Tabs** → tap History, Settings; scroll Home, switch away/back → scroll preserved. (SC-009)
3. **Actions** → tap Gửi → full-screen ComingSoon, bottom bar hidden, back → Home; repeat Nhận. (SC-002)
4. **Dark mode** → toggle OS theme → whole shell flips palette, text legible. (SC-003)
5. **Language** → switch device VI↔EN → tab labels + titles change; set an unsupported locale → VI shown. (SC-004)
6. **Reduce Motion** → enable → no decorative animation plays. (SC-005)
7. **Dynamic Type** → increase font size → layouts adapt, no clipping. (SC-006)
8. **Devices** → run on a notch/Dynamic Island device + a cutout device → content within safe area. (SC-006)
9. **Components** → confirm every shared widget (plan/contracts) is used by ≥1 shell screen. (SC-007)
10. **Flavors** → build/launch dev + prod on iOS + Android. (SC-008)

## Done when
All SC-001…SC-009 verified, `flutter analyze` = 0, `flutter test` green, `bloc_lint` = 0, `dart format` clean.
