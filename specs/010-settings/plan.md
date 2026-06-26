# Implementation Plan: Settings & Preferences (Cài đặt)

**Branch**: `010-settings` | **Date**: 2026-06-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/010-settings/spec.md`

## Summary

Turn the placeholder Settings tab (#001) into the app's real preferences surface and wire the chosen preferences into the rest of the app. A single `SettingsRepository` (core, `shared_preferences`-backed) becomes the one source of truth for: device name, three behavior toggles (auto-receive / save-to-library / notifications), theme mode, language, and a signaling-endpoint override. An app-wide `SettingsCubit` mounted above `MaterialApp.router` makes theme + language switch at runtime; the receive flow reads auto-receive (foreground skip-tap), an incoming-file local notification fires when enabled, received media is copied to the photo library when enabled, and the signaling layer honours the validated endpoint override. The device name replaces the #009 inline-generated nearby label and is carried to the receiver via one additive, backward-compatible `senderName` field on the existing transfer manifest so the accept prompt and history show the real name.

**Primary requirements**: FR-001..FR-023 (device profile, toggle group, appearance/language, advanced signaling, about, local-only persistence + cross-feature contract).

## Technical Context

**Language/Version**: Dart `^3.11.0` (project floor) / Flutter `>=3.41.0`
**Primary Dependencies (new)**: `shared_preferences ^2.5.5` (prefs), `package_info_plus ^10.1.0` (version), `in_app_review ^2.0.12` (rate), `gal ^2.3.2` (save media to library), `flutter_local_notifications ^22.0.1` (incoming-file notification). Reuses `permission_handler ^12.0.3` (#007), `web_socket_channel` (#003, diagnostics), `flutter_bloc`, `get_it`/`injectable`, `go_router`, `intl`.
**Storage**: `shared_preferences` (key-value, app-private) for all preferences. No drift/schema change. No cloud.
**Testing**: `flutter_test` + `bloc_test` + `mocktail`; `SharedPreferences.setMockInitialValues` for repo tests; fake `SettingsRepository` for cubit/receive tests.
**Target Platform**: iOS 13+ / Android 8.0 (API 26)+. (All new packages' platform minimums ≤ project floor.)
**Project Type**: Mobile app (Flutter, Clean Architecture + feature-first, BLoC).
**Performance Goals**: N/A for a settings surface; theme/language switch must apply without app restart (SC-004); preferences load before first frame (no flash of wrong theme).
**Constraints**: `lib/core/` must not import `lib/features/` (XI); fixed palette — mode only (VI); VI-primary ARB (XIV); single source of truth per preference (FR-020); no peer identifiers / secrets in logs (I).
**Scale/Scope**: 1 settings tab + 2 sub-pages (how-it-works, privacy). ~6 preferences. One app-wide cubit, screen-scoped editing via the same cubit + use cases.

### Package verification (Constitution XV — verified on pub.dev 2026-06-26)

| Package | Version | Env floor | Platform min | Native config |
|---|---|---|---|---|
| `shared_preferences` | `^2.5.5` | Flutter-team, ≤ our floor | iOS 13 / Android 24 | none |
| `package_info_plus` | `^10.1.0` | Flutter ≥3.38.1 · Dart ≥3.10 ✓ | iOS 13 / Android 21 | none |
| `in_app_review` | `^2.0.12` | ≤ our floor | iOS 10.3 / Android 21 (needs Play Store) | none |
| `gal` | `^2.3.2` | ≤ our floor | iOS 11 / Android 21 | iOS `NSPhotoLibraryAddUsageDescription` (+ `NSPhotoLibraryUsageDescription`); Android `WRITE_EXTERNAL_STORAGE` `maxSdkVersion=29` |
| `flutter_local_notifications` | `^22.0.1` | Flutter ≥3.38.1 ✓ · **AGP ≥8.11.1 + compileSdk 35** | iOS 10 / Android (NotificationCompat) | Android `POST_NOTIFICATIONS` (API 33+); iOS runtime auth request |

> **Key risk cleared**: `flutter_local_notifications` 22.x requires AGP 8.11.1 + compileSdk 35. The project is **already on AGP 8.11.1 / Gradle 8.14** ([android/settings.gradle.kts:22](../../android/settings.gradle.kts#L22)) with `compileSdk = flutter.compileSdkVersion` (35+ on Flutter 3.41) → **no Gradle/AGP bump required**. Exact `environment:` ranges to be re-confirmed at `flutter pub get`; if any latest pins above the Dart 3.11 floor, fall back one minor (mirrors the #008 `app_links` 6.x pin). `gal` chosen over the unmaintained `image_gallery_saver` (add-only library access, actively maintained).

## Constitution Check

*GATE: must pass before Phase 0 and re-checked after Phase 1.*

| Principle | Status | Notes |
|---|---|---|
| I. Privacy-First P2P | ✅ | Prefs are app-private. The new manifest `senderName` is a user-set label, never a file path/secret; it MUST NOT be logged (I). No bytes touch signaling. Signaling override validated (no plaintext in prod — FR-014). |
| II. Direct Transfer & Data Minimization | ✅ | No content retained. Save-to-library copies only user-received media to the user's own library. |
| III. BLoC 4-state | ✅ | App-wide `@lazySingleton SettingsCubit` (4-state freezed) drives MaterialApp + Settings page; injects use cases, not the repo directly; side effects via `BlocListener`. |
| IV. Code Quality & Dart Safety | ✅ | `very_good_analysis` zero-warning; explicit types; freezed state. |
| V. Result\<T\> | ✅ | Repo/services return `Result<T>`; add `AppFailure` variants for invalid endpoint + permission-blocked save/notify (reuse `permissionDenied`). |
| VI. Design System & Theming | ✅ | Reuses `ToggleRow`/`SegmentedTabs`/tokens; **this is the spec that introduces the sanctioned theme-mode picker** (light/dark/system) — no color-scheme picker. |
| VII. Cross-Platform Native | ✅ | Photo-library + notification permissions requested contextually, degrade on denial (FR-010); platform-adaptive pickers; Info.plist/manifest entries added. |
| VIII. Transport & Signaling | ⚠️→✅ | One additive, **versioned, backward-compatible** manifest field (`senderName`) + a centralized `SignalingEndpointProvider` (override ?? per-flavor default) — config stays centralized, not hardcoded at call sites. Justified in Complexity Tracking. |
| IX. Transfer Reliability | ✅ | No change to integrity/atomicity; auto-receive never hijacks an in-flight transfer (FR-007 / Edge Cases). |
| X. go_router | ✅ | New routes via `AppRoutes` (settings sub-pages); notification tap reuses existing routing into Receive. |
| XI. Feature-First Modularity | ✅ | `SettingsRepository` interface in `core/domain/settings/`, impl in `core/data/`; feature reads via DI; `core/` imports no features. |
| XII. Testing Discipline | ✅ | Repo round-trip, cubit bloc_tests, widget tests for the page + edit dialog + pickers; receive auto-accept test; manifest senderName round-trip (loopback). Two-device smoke deferred (device task). |
| XIII. Simplicity & YAGNI | ✅ | No trusted-peer registry (auto-receive = foreground skip-tap only); no folder chooser; in-app privacy page (no hosted-URL dependency). 5 packages each justified by a concrete FR. |
| XIV. i18n | ✅ | All copy via ARB (VI primary + EN, `@description`); language switch honours fallback to VI. |
| XV. Dependency Hygiene | ✅ | Versions verified on pub.dev (table above); caret constraints; AGP requirement pre-satisfied; lockfile churn expected at first `pub get`/`pod install`. |

**Gate result**: PASS (one justified protocol extension — see Complexity Tracking).

## Project Structure

### Documentation (this feature)

```text
specs/010-settings/
├── plan.md              # this file
├── spec.md              # feature spec (clarified)
├── research.md          # Phase 0 — package + architecture decisions
├── data-model.md        # Phase 1 — AppSettings/DeviceProfile/enums + manifest field
├── quickstart.md        # Phase 1 — manual verification script
├── contracts/
│   └── settings_repository.md   # SettingsRepository + service contracts
├── checklists/
│   └── requirements.md  # spec quality checklist (passing)
└── tasks.md             # Phase 2 — /speckit.tasks (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── app/
│   ├── app.dart                      # EDIT: wrap MaterialApp.router in BlocBuilder<SettingsCubit> → themeMode + locale
│   └── view/deep_link_listener.dart  # reuse for notification-tap routing into Receive
├── bootstrap.dart                    # EDIT: await settings preload before runApp (no theme/locale flash)
├── core/
│   ├── config/
│   │   ├── app_config.dart            # unchanged (per-flavor default endpoint)
│   │   └── signaling_endpoint_provider.dart   # NEW: effective = override ?? flavor default
│   ├── constants/app_routes.dart      # EDIT: + settingsHowItWorks, settingsPrivacy
│   ├── domain/
│   │   ├── settings/
│   │   │   ├── app_settings.dart       # NEW: freezed snapshot of all prefs
│   │   │   ├── device_profile.dart     # NEW: name + initial-avatar helper
│   │   │   ├── preference_enums.dart    # NEW: ThemePreference, LanguagePreference
│   │   │   └── settings_repository.dart # NEW: abstract interface (watch + getters + setters)
│   │   └── transfer/…manifest          # EDIT: add optional `senderName` (additive, versioned) + codec
│   ├── services/transport/…engine       # EDIT (send path): attach settings.deviceName as manifest senderName
│   ├── data/
│   │   └── shared_preferences_settings_repository.dart  # NEW: @LazySingleton(as: SettingsRepository)
│   ├── services/
│   │   ├── permissions/photo_library_permission_service.dart  # NEW (mirror CameraPermissionService)
│   │   ├── permissions/notification_permission_service.dart   # NEW
│   │   ├── media/gallery_saver_service.dart                   # NEW: wraps gal
│   │   ├── notifications/incoming_file_notifier.dart          # NEW: wraps flutter_local_notifications
│   │   └── signaling/signaling_diagnostics_service.dart       # NEW: endpoint reachability
│   └── di/                            # injectable codegen picks up new @LazySingleton/@injectable
└── features/
    ├── settings/
    │   ├── domain/usecases/           # NEW: LoadSettings, SaveThemeMode, SaveLanguage,
    │   │                              #      SaveDeviceName(+validate), ToggleAutoReceive/SaveToLibrary/Notifications,
    │   │                              #      SaveSignalingEndpoint(+validate), RunSignalingDiagnostic, RateApp, AppVersionInfo
    │   └── presentation/
    │       ├── cubit/settings_cubit.dart   # NEW: @lazySingleton app-wide, 4-state
    │       ├── settings_page.dart          # EDIT placeholder → real wiring
    │       ├── widgets/                     # device-profile card+edit, theme picker, language picker,
    │       │                                #  advanced (endpoint+diagnostic), about section
    │       └── pages/how_it_works_page.dart, pages/privacy_policy_page.dart   # NEW in-app
    ├── receive/presentation/cubit/receive_transfer_cubit.dart  # EDIT: auto-receive seam + notif + senderName label
    └── pairing/.../nearby_advertise_panel.dart                 # EDIT: read device name from settings (drop inline UUID)

lib/l10n/arb/app_vi.arb · app_en.arb     # EDIT: settings section copy + about/how-it-works/privacy + failure strings
ios/Runner/Info.plist                     # EDIT: NSPhotoLibraryAddUsageDescription (+ Usage); notifications need no key
android/app/src/main/AndroidManifest.xml  # EDIT: POST_NOTIFICATIONS + WRITE_EXTERNAL_STORAGE(maxSdk 29)
```

**Structure Decision**: Standard feature-first layout. The shared contract (`SettingsRepository`) and the cross-cutting services (permissions, gallery saver, notifier, endpoint provider, diagnostics) live in `core/` because four features read preferences and `core/` cannot import features (XI). The app-wide `SettingsCubit` is the only legitimate `@lazySingleton` cubit (it backs both `MaterialApp` and the Settings page — single source of truth, FR-020). Editing flows reuse that cubit + injected use cases rather than spawning competing state.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Additive `senderName` field on the transfer manifest (first protocol touch since #002) | US1 (P1) requires the custom device name to appear as the **sender's** label in the receiver's accept prompt and in history; the manifest is the only channel that reaches the receiver for 6-digit/QR/share-link methods (nearby already carries it via TXT). | "Nearby-only name" rejected: it would leave the receive prompt and history showing the generic label for 3 of 4 pairing methods, directly failing US1's "every peer that **receives** from this device sees the new name." The field is optional + versioned + backward-compatible (older peers send empty → existing generic label), and it also fills #006's currently-empty `peerLabel`. Never logged (I). |
| App-wide `@lazySingleton SettingsCubit` above `MaterialApp` | Theme + language must switch at runtime (SC-004) → `MaterialApp` must rebuild from a single observed source that is also the Settings page's state. | A separate page cubit + a second theme controller rejected: two sources of truth for the same prefs (violates FR-020) and risks theme/page divergence. |
