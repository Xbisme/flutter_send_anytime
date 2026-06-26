# Phase 0 Research: Settings & Preferences (#010)

All decisions verified against the existing codebase seams (see plan.md Technical Context) and pub.dev (2026-06-26, Constitution XV). No open NEEDS CLARIFICATION remain (spec clarifications resolved Q1–Q7).

---

## D1 — Preferences storage & the cross-feature contract

**Decision**: A single `SettingsRepository` interface in `lib/core/domain/settings/`, implemented by `SharedPreferencesSettingsRepository` in `lib/core/data/` (`@LazySingleton(as: SettingsRepository)`), backed by `shared_preferences ^2.5.5`. It loads all keys into an in-memory `AppSettings` snapshot at startup, exposes a synchronous `current` getter **and** a broadcast `Stream<AppSettings> watch()`; every setter writes the key, updates the snapshot, and emits.

**Rationale**: `shared_preferences` is the Flutter-team standard for small key-value prefs; drift is reserved for transfer history (Constitution: "drift for transfer history only"). A synchronous snapshot lets `MaterialApp` read theme/locale on the first frame with no async flash; the stream gives reactive updates (SC-004). One repo = one source of truth per preference (FR-020). Mirrors the existing `TransferHistoryRepository` core-interface/core-impl split (XI).

**Alternatives considered**: drift table for prefs (rejected — over-engineered, violates "history only" + adds a migration surface); per-feature ad-hoc `SharedPreferences` reads (rejected — multiple sources of truth, FR-020); `Hive`/`isar` (rejected — new heavy dep, YAGNI XIII).

---

## D2 — Runtime theme + language switching

**Decision**: Wrap `MaterialApp.router` in [lib/app/app.dart](../../lib/app/app.dart) with a `BlocBuilder<SettingsCubit, SettingsState>` that maps `ThemePreference → ThemeMode` (`light/dark/system`) into `MaterialApp.themeMode`, and `LanguagePreference → Locale?` into `MaterialApp.locale` (`null` ⇒ keep the existing `localeResolutionCallback` system behaviour; `vi`/`en` ⇒ explicit). The app-wide `SettingsCubit` (`@lazySingleton`) is provided above `MaterialApp` and subscribes to `SettingsRepository.watch()`.

**Rationale**: `app.dart` today hardcodes `themeMode: system` and system-only locale (Explore seam #1/#2). A `BlocBuilder` at the root is the BLoC-idiomatic way (III) to rebuild `MaterialApp` on preference change without a restart (SC-004). Keeping `locale: null` for "system" preserves the existing VI-fallback `localeResolutionCallback` untouched.

**Alternatives**: `ValueNotifier`/`InheritedWidget` theme controller (rejected — bypasses BLoC discipline III, second source of truth); restart-to-apply (rejected — fails SC-004).

**Preload**: [bootstrap.dart](../../lib/bootstrap.dart) awaits `SettingsRepository` init (first `SharedPreferences.getInstance()`) before `runApp` so the first frame already has the correct theme/locale (no flash). The default device name is generated-and-persisted on this first init if absent (so it is stable thereafter and available to #009 nearby advertise).

---

## D3 — Device name: persistence, default, and reaching the peer

**Decision**: Store `deviceName` in `SettingsRepository`. On first init, if absent, generate the existing-style default (`Safe Send · XXXX`) **once** and persist it (moving generation out of the inline UUID in [nearby_advertise_panel.dart](../../lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart)). The nearby advertise panel reads the name from settings instead of generating it. To surface the name to the **receiver** across all pairing methods, add one **optional, versioned, backward-compatible** `senderName` field to the transfer manifest; the receiver populates the accept-prompt `senderLabel` and the history `peerLabel` from it (empty ⇒ existing generic localized label).

**Rationale**: Nearby already transmits the name via mDNS TXT, but 6-digit/QR/share-link transmit no identity — the manifest is the only channel that reaches the receiver before accept (Explore seam #4/#5). US1 (P1) explicitly requires the name to show where a peer "receives from this device." Extending the already-versioned manifest (Constitution VIII lists the manifest as part of the protocol) is the minimal honest way; it is additive (older senders omit it → unchanged behaviour) and also fills #006's currently-empty `peerLabel`. Validation: trimmed, non-empty, ≤30 chars, unicode (FR-002 / Q-name). Never logged (Constitution I — it is a peer identifier).

**Alternatives**: nearby-only name (rejected — fails US1 for 3/4 methods); add a name to the signaling/SDP exchange (rejected — signaling is metadata-only and per-room, the manifest is the natural per-transfer carrier); a separate "hello" control frame (rejected — more protocol surface than a single manifest field, YAGNI).

---

## D4 — Auto-receive (foreground skip-tap)

**Decision**: Inject `SettingsRepository` into `ReceiveTransferCubit`. In the existing `onManifest` callback (the `_decision` Completer seam, Explore #5), before surfacing the prompt: if `current.autoReceive` **and** `WidgetsBinding.instance.lifecycleState == resumed`, immediately `_decision.complete(true)` and skip the dialog; otherwise behave exactly as today. Never auto-accept a manifest that arrives while another transfer is already in progress (guarded by the cubit's existing single-transfer state).

**Rationale**: The receive cubit only runs inside the active receive flow, so "on the receive screen" is structural; the only extra check needed is app-foreground (lifecycle resumed) per Q1 (no unattended/background receive — that awaits the v1.1 saved-peer registry). This is the single additive edit to merged receive code, mirroring the one-seam pattern of #004/#005/#006.

**Alternatives**: global background auto-accept (rejected — Q1; no trusted-peer model, security risk); a new wrapper service intercepting manifests (rejected — duplicates the existing decision Completer).

---

## D5 — Save received media to the photo library

**Decision**: `gal ^2.3.2` behind a core `GallerySaverService` (interface + `@LazySingleton` impl), gated by a `PhotoLibraryPermissionService` (mirror of the #007 `CameraPermissionService`, Explore #10). When `saveToLibrary` is ON and a completed received item's mime is image/video, copy it into the library **in addition to** the existing #005 app-sandbox save (additive — non-media untouched, FR-008). Permission requested on toggle-enable; denial ⇒ toggle reflects blocked + Open Settings (FR-010).

**Rationale**: `gal` is actively maintained, uses add-only library access (`NSPhotoLibraryAddUsageDescription`), iOS 11 / Android 21 ≤ floor. The existing save model stays the baseline; library copy is layered on (Assumptions). The hook is the receive terminal/per-file-complete branch (same place #006 records history).

**Alternatives**: `image_gallery_saver(_plus)` (rejected — original unmaintained; `gal` is the current community standard); replacing the sandbox save (rejected — breaks the share-sheet/open model from #005).

---

## D6 — Incoming-file local notification

**Decision**: `flutter_local_notifications ^22.0.1` behind a core `IncomingFileNotifier` service, gated by a `NotificationPermissionService`. When `notifications` is ON and a manifest arrives while the app is **not** foregrounded, show an immediate local notification ("Có file đến từ <senderName>"). Tapping routes into the receive screen for that transfer by reusing the existing routing path ([deep_link_listener.dart](../../lib/app/view/deep_link_listener.dart) / the active receive route) — FR-009. Immediate `show()` only; **no** scheduling ⇒ no `timezone` init needed (simpler).

**Rationale**: AGP 8.11.1 + compileSdk 35 (the package's 22.x requirement) are already in place (plan.md risk note) → no Gradle churn. Android 13+ needs the `POST_NOTIFICATIONS` runtime permission; iOS requests authorization at first enable. Notifying only when backgrounded avoids a redundant banner over the visible receive screen.

**Alternatives**: full deferral to #011 (rejected — Q2 = implement now); `awesome_notifications` (rejected — heavier, not needed); scheduled/zoned notifications (rejected — YAGNI, only "on arrival" is required).

---

## D7 — Signaling endpoint override + diagnostics

**Decision**: A core `SignalingEndpointProvider` (`lib/core/config/`) returns the **effective** endpoint = `settings.signalingOverride ?? AppConfig.signalingEndpoint`. `SignalingClient.create` reads the effective endpoint from this provider instead of `AppConfig` directly (small constructor edit, Explore #3). Validation (a use case / value validator): accept `wss://` in any flavor, `ws://` **only** in the dev flavor, reject anything else (FR-014). Diagnostics: a `SignalingDiagnosticsService` opens a `WebSocketChannel` to the effective endpoint with a short timeout and returns `Result<void>` → "reachable / unreachable" copy (FR-015). Clearing the override restores the flavor default.

**Rationale**: Keeps signaling config centralized (Constitution VIII — "never hardcoded at call sites"); the override is just another centralized source. Reuses `web_socket_channel` (#003) for the reachability probe; no new dep. The prod-`wss`-only rule preserves the no-plaintext-signaling guarantee (Q-endpoint, Principle I).

**Alternatives**: mutate `AppConfig` at runtime (rejected — it is an immutable per-flavor const registered once); reconnect-on-change side effects (rejected — override applies to the *next* pairing per FR-013, no live socket to migrate).

---

## D8 — About: version, how-it-works, privacy, rate

**Decision**: `package_info_plus ^10.1.0` for the build version (FR-016, tagline "Safe Send v1.0.0 · WebRTC P2P"); `in_app_review ^2.0.12` for the native rate flow (FR-018). How-it-works and privacy are **in-app localized pages** (new `AppRoutes.settingsHowItWorks` / `settingsPrivacy`), no external/hosted URL (Q-privacy, FR-017) — a hosted URL can replace the privacy page at #011.

**Rationale**: In-app pages have no external dependency, work offline, and stay in the VI-primary ARB system (XIV). `package_info_plus` 10.1.0 is within the Dart 3.11 floor (Dart ≥3.10).

**Alternatives**: hosted privacy URL now (rejected — Q-privacy; URL doesn't exist yet, would block); hardcoded version string (rejected — must read the real build, FR-016).

---

## D9 — App-wide cubit vs page cubit

**Decision**: One `@lazySingleton SettingsCubit` (4-state freezed) subscribes to `SettingsRepository.watch()`, drives both `MaterialApp` (theme/locale) and the Settings page, and exposes intent methods that call injected use cases. Screen-scoped editing (name dialog, advanced endpoint) dispatches through the same cubit; the repo stream closes the loop so every surface stays consistent.

**Rationale**: Theme/locale and the Settings page must reflect the same prefs simultaneously; a single app-wide cubit is the only way to avoid two sources of truth (FR-020). Constitution III sanctions `@lazySingleton` for app-wide cubits.

**Alternatives**: separate `ThemeCubit` + `SettingsPageCubit` (rejected — divergence risk, more wiring for no benefit).

---

## D10 — Native configuration

**Decision & rationale** (verified package docs):
- **iOS** [Info.plist](../../ios/Runner/Info.plist): add `NSPhotoLibraryAddUsageDescription` (+ `NSPhotoLibraryUsageDescription` for completeness) for `gal`; VI+EN strings. Notifications need no plist key (runtime `requestPermissions`). First `pod install` will churn `ios/Podfile.lock` (the gal + flutter_local_notifications pods) — deferred to the device build, consistent with #006–#009.
- **Android** [AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml): add `POST_NOTIFICATIONS` (API 33+) and `WRITE_EXTERNAL_STORAGE` with `android:maxSdkVersion="29"` (gal legacy save). AGP 8.11.1 / compileSdk 35 already satisfied → no Gradle edit.
- `shared_preferences` / `package_info_plus` / `in_app_review` need no native config.

**Open follow-up (device-only, deferred like prior specs)**: first `pod install`; two-device smoke that the custom name shows on the peer's accept prompt and that auto-receive/notification/library-save behave on real devices.
