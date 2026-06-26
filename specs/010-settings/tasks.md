---
description: "Task list for Settings & Preferences (#010)"
---

# Tasks: Settings & Preferences (Cài đặt)

**Input**: Design documents from `/specs/010-settings/`
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/settings_repository.md](contracts/settings_repository.md)

**Tests**: INCLUDED — Constitution XII requires unit tests for business logic, `bloc_test` for all Cubits, and widget tests for transfer-critical flows. Test tasks are interleaved per story.

**Organization**: Tasks grouped by user story (priority order). US1 + US2 are both P1 → together they are the MVP.

> ⚠️ **Two-physical-device smoke (Constitution XII) — DEFERRED, device-only**: (a) custom device name appears on the peer's accept prompt + History across all 4 pairing methods; (b) auto-receive skips the tap when foregrounded; (c) save-to-library writes received media to the photo library; (d) incoming-file notification fires when backgrounded and its tap opens Receive. Tracked here; run on the first device build. Also: first `pod install` will churn `ios/Podfile.lock` (gal + flutter_local_notifications pods).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1–US5; Setup/Foundational/Polish have no story label

## Path Conventions

Flutter Clean Architecture, feature-first (Constitution XI): `lib/core/`, `lib/features/settings/`, tests mirror under `test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependencies + native config that everything else builds on.

- [X] T001 Add `shared_preferences ^2.5.5`, `package_info_plus ^10.1.0`, `in_app_review ^2.0.12`, `gal ^2.3.2`, `flutter_local_notifications ^22.0.1` to `pubspec.yaml` (caret constraints) and run `flutter pub get`; if any latest pins above the Dart 3.11 floor, fall back one minor and note it (mirror #008 app_links pin). Commit `pubspec.lock`.
- [X] T002 [P] Add `NSPhotoLibraryAddUsageDescription` (+ `NSPhotoLibraryUsageDescription`) VI/EN strings to `ios/Runner/Info.plist` (gal add-only access).
- [X] T003 [P] Add `POST_NOTIFICATIONS` (API 33+) and `WRITE_EXTERNAL_STORAGE` `android:maxSdkVersion="29"` to `android/app/src/main/AndroidManifest.xml`. Confirm AGP 8.11.1/compileSdk 35 already present (no Gradle edit).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The settings contract, persistence, app-wide cubit, and page shell that ALL stories depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T004 [P] Create `ThemePreference` + `LanguagePreference` enums in `lib/core/domain/settings/preference_enums.dart`.
- [X] T005 [P] Create `DeviceProfile` value helper (name + derived initial) in `lib/core/domain/settings/device_profile.dart`.
- [X] T006 Create `AppSettings` freezed snapshot (deviceName, autoReceive, saveToLibrary, notifications, theme, language, signalingOverride) with documented defaults in `lib/core/domain/settings/app_settings.dart`.
- [X] T007 Create `SettingsRepository` abstract interface (init/current/watch + 7 validating setters returning `Result`) in `lib/core/domain/settings/settings_repository.dart` (per [contracts/settings_repository.md](contracts/settings_repository.md)).
- [X] T008 Add `invalidSignalingEndpoint` variant to `AppFailure` (`lib/core/domain/`) + reuse `permissionDenied`/`networkError`; wire the localized mapper entries.
- [X] T009 Implement `SharedPreferencesSettingsRepository` (`@LazySingleton(as: SettingsRepository)`) in `lib/core/data/shared_preferences_settings_repository.dart`: load-into-snapshot on `init()`, generate-and-persist default device name if absent, name validation (trim/non-empty/≤30), endpoint validation (wss any / ws dev-only), broadcast `watch()`. MUST NOT log the device name or endpoint (Principle I).
- [X] T010 Run `dart run build_runner build --delete-conflicting-outputs` (freezed for AppSettings/state + injectable graph). Verify `injection.config.dart` registers the repo.
- [X] T011 Preload settings in `lib/bootstrap.dart`: `await getIt<SettingsRepository>().init()` before `runApp` (no theme/locale flash).
- [X] T012 Create 4-state `SettingsState` (freezed) + app-wide `SettingsCubit` (`@lazySingleton`) subscribing to `SettingsRepository.watch()`, exposing intent methods (delegating to use cases added per story) in `lib/features/settings/presentation/cubit/`.
- [X] T013 Provide `SettingsCubit` above `MaterialApp.router` via `BlocProvider` in `lib/app/app.dart` (binding of themeMode/locale comes in US3; provider is foundational so every surface reads one source).
- [X] T014 Replace the #001 placeholder body of `lib/features/settings/presentation/settings_page.dart` with a `BlocBuilder<SettingsCubit>` scaffold (header "Cài đặt" + section slots for profile/toggles/appearance/advanced/about) reading from `loaded` state; sections filled per story.
- [X] T015 [P] Add the settings ARB section scaffolding (titles, VI primary + EN, `@description`) to `lib/l10n/arb/app_vi.arb` + `app_en.arb`; regenerate l10n.
- [X] T016 [P] Foundational tests: `SharedPreferencesSettingsRepository` round-trip + defaults + validation (name, endpoint dev/prod) over `SharedPreferences.setMockInitialValues` in `test/core/data/shared_preferences_settings_repository_test.dart`; `SettingsCubit` load/emit `bloc_test` in `test/features/settings/presentation/settings_cubit_test.dart`.

**Checkpoint**: Settings persist + the page shows live state; user-story sections can now be built in parallel.

---

## Phase 3: User Story 1 - Personalize how I appear to other devices (Priority: P1) 🎯 MVP

**Goal**: Editable device name persists and is surfaced as this device's peer label across pairing methods.

**Independent Test**: Edit the name, restart, confirm it persists; confirm it appears in a nearby/receive peer label (device step deferred).

### Implementation

- [X] T017 [P] [US1] `SaveDeviceNameUseCase` (validates via repo) in `lib/features/settings/domain/usecases/save_device_name_usecase.dart`.
- [X] T018 [US1] Device-profile card + edit dialog widget (avatar initial, name, pencil; rejects empty/>30) in `lib/features/settings/presentation/widgets/device_profile_card.dart`; wire into `settings_page.dart` (FR-001/002/003).
- [X] T019 [P] [US1] Add optional `senderName` field to the transfer manifest in `lib/core/domain/transfer/` (additive, versioned, backward-compatible; absent ⇒ generic label). Update the protocol codec + bump no breaking version.
- [X] T020 [US1] Sender: include `settings.current.deviceName` as `senderName` when building the manifest on the send path in `lib/core/services/transport/` (TransferEngine `_runSend`/manifest-build seam — the file enumerated in plan.md Project Structure). Never log it.
- [X] T021 [US1] Receiver: map manifest `senderName` → `ReceiveTransferCubit` `senderLabel` (fallback to existing generic label when empty) in `lib/features/receive/presentation/cubit/receive_transfer_cubit.dart`.
- [X] T022 [US1] History: populate `peerLabel` from manifest `senderName` in the receive record mapper (`features/receive/...` mapper) — fills #006's previously-empty field.
- [X] T023 [US1] Nearby advertise: replace the inline UUID name in `lib/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart` with `settings.current.deviceName`.
- [X] T024 [P] [US1] Tests: `SaveDeviceNameUseCase` validation matrix (`test/features/settings/domain/save_device_name_usecase_test.dart`); device-profile card widget test (edit/persist/reject) (`test/features/settings/presentation/device_profile_card_test.dart`); manifest `senderName` loopback round-trip + empty-fallback (`test/core/transfer/manifest_sender_name_test.dart`); nearby panel reads settings name.

**Checkpoint**: Device name editable, persisted, and threaded to receiver/history/nearby.

---

## Phase 4: User Story 2 - Control how incoming files are handled (Priority: P1) 🎯 MVP

**Goal**: Auto-receive / save-to-library / notifications toggles persist and change receive behavior.

**Independent Test**: Toggle each, restart (persist); auto-receive ON foregrounded → no prompt; save-to-library ON → media in library; notification on arrival (device steps deferred).

### Implementation

- [X] T025 [P] [US2] `PhotoLibraryPermissionService` (interface + `@LazySingleton` impl) in `lib/core/services/permissions/photo_library_permission_service.dart` (mirror #007 `CameraPermissionService`).
- [X] T026 [P] [US2] `NotificationPermissionService` (interface + impl) in `lib/core/services/permissions/notification_permission_service.dart`.
- [X] T027 [P] [US2] `GallerySaverService` (interface + `@LazySingleton` impl wrapping `gal`) in `lib/core/services/media/gallery_saver_service.dart` (returns `Result`).
- [X] T028 [P] [US2] `IncomingFileNotifier` (interface + impl wrapping `flutter_local_notifications`, immediate `show` only, init in bootstrap) in `lib/core/services/notifications/incoming_file_notifier.dart`.
- [X] T029 [US2] Toggle use cases (`ToggleAutoReceiveUseCase`, `ToggleSaveToLibraryUseCase` w/ permission gate, `ToggleNotificationsUseCase` w/ permission gate) in `lib/features/settings/domain/usecases/`.
- [X] T030 [US2] Toggle-group section widget (3 `ToggleRow`s; on-enable permission request; blocked state + Open Settings on denial, FR-010) in `lib/features/settings/presentation/widgets/preferences_section.dart`; wire into `settings_page.dart`.
- [X] T031 [US2] Auto-receive seam: inject `SettingsRepository` + app-lifecycle check into `ReceiveTransferCubit.onManifest` — auto-`complete(true)` when `autoReceive` ON and lifecycle `resumed`; never while another transfer is in progress (FR-007).
- [X] T032 [US2] Save-to-library hook: in the receive per-file-complete/terminal branch, when `saveToLibrary` ON and mime is image/video, call `GallerySaverService` in addition to the existing #005 save (FR-008).
- [X] T033 [US2] Notification hook: in `onManifest`, when `notifications` ON and app NOT foregrounded, `IncomingFileNotifier.showIncoming(senderName)`. **Tap mechanism** (FR-009): the receive transfer is already in-app/active, so the OS tap brings the app to the foreground and the notifier's tap-callback ensures the **already-mounted receive route is the visible route** (`context.go(AppRoutes.receive…)` if not current) — it does NOT create a synthetic deep link or a second join. Init the notifier in `bootstrap.dart` and register the tap-callback to the router. (Latest-wins / no interruption of an in-flight transfer per FR-007 edge case.)
- [X] T034 [P] [US2] Tests: `SettingsCubit` toggle + permission-blocked `bloc_test`; `ReceiveTransferCubit` auto-accept-when-foregrounded vs prompt-when-off `bloc_test` (`test/features/receive/.../auto_receive_test.dart`); save-to-library hook gated by setting (`test/.../save_to_library_test.dart`); `IncomingFileNotifier`/permission-service unit tests with mocktail.

**Checkpoint**: MVP (US1 + US2) complete — Settings drives identity + incoming-file behavior.

---

## Phase 5: User Story 3 - Appearance & language (Priority: P2)

**Goal**: Theme (light/dark/system) + language (VI/EN/system) switch app-wide at runtime and persist.

**Independent Test**: Pick Tối + English → app re-renders immediately; restart → persists; system options follow OS.

### Implementation

- [X] T035 [P] [US3] `SaveThemeUseCase` + `SaveLanguageUseCase` in `lib/features/settings/domain/usecases/`.
- [X] T036 [P] [US3] Theme picker widget — a **3-way** control (Sáng / Tối / Theo hệ thống), NOT the binary "Giao diện tối" ToggleRow shown in the ui-design Screen 08 mock (spec FR-011 is authoritative for the 3 options; render token-consistent, e.g. `SegmentedTabs` or 3 radio rows) in `lib/features/settings/presentation/widgets/theme_section.dart`.
- [X] T037 [P] [US3] Language picker widget (Tiếng Việt/English/Theo hệ thống) in `lib/features/settings/presentation/widgets/language_section.dart`; wire both into `settings_page.dart`.
- [X] T038 [US3] Bind `MaterialApp.router` in `lib/app/app.dart`: `BlocBuilder<SettingsCubit>` → `themeMode` (ThemePreference→ThemeMode) + `locale` (LanguagePreference→Locale?, system⇒null keeps the existing VI-fallback callback). (Builds on the provider from T013.)
- [X] T039 [P] [US3] Tests: `SaveTheme/SaveLanguage` use-case tests; app-level widget test that switching theme→dark and language→en rebuilds `MaterialApp` (`test/app/theme_locale_switch_test.dart`).

**Checkpoint**: Appearance + language fully runtime-switchable.

---

## Phase 6: User Story 4 - Advanced: self-hosted signaling endpoint (Priority: P3)

**Goal**: Override the signaling endpoint (validated) + run a reachability diagnostic; clearing restores the flavor default.

**Independent Test**: Save `wss://…` → next pairing uses it; diagnostic reports reachable/unreachable; `ws://` rejected in prod / accepted in dev; clear → default returns.

### Implementation

- [X] T040 [P] [US4] `SignalingEndpointProvider` (`effective() = override ?? flavor default`) in `lib/core/config/signaling_endpoint_provider.dart` (`@LazySingleton`).
- [X] T041 [P] [US4] `SignalingDiagnosticsService` (ws connect + timeout → `Result`) in `lib/core/services/signaling/signaling_diagnostics_service.dart`.
- [X] T042 [US4] `SaveSignalingEndpointUseCase` (validation) + `RunSignalingDiagnosticUseCase` in `lib/features/settings/domain/usecases/`.
- [X] T043 [US4] Wire `SignalingClient.create` to read `SignalingEndpointProvider.effective()` instead of `AppConfig.signalingEndpoint` directly (`lib/core/services/signaling/`); keep config centralized (Constitution VIII).
- [X] T044 [US4] Advanced section widget (endpoint field + validation feedback + "Kiểm tra kết nối" diagnostic + clear) in `lib/features/settings/presentation/widgets/advanced_section.dart`; wire into `settings_page.dart`.
- [X] T045 [P] [US4] Tests: endpoint validation matrix (wss any / ws dev-only / other rejected) + provider fallback unit tests; diagnostic Result mapping with a fake channel; `SettingsCubit` save-endpoint `bloc_test`.

**Checkpoint**: Self-host override + diagnostics functional.

---

## Phase 7: User Story 5 - About (version, how-it-works, privacy, rate) (Priority: P3)

**Goal**: Show build version + tagline, in-app how-it-works + privacy pages, native rate action.

**Independent Test**: Version matches build; open how-it-works/privacy in-app; rate triggers the native sheet.

### Implementation

- [X] T046 [P] [US5] `AppInfoService` (version via `package_info_plus`) in `lib/core/services/app_info_service.dart` (`@LazySingleton`) + `RateAppUseCase` (`in_app_review`) in `lib/features/settings/domain/usecases/`.
- [X] T047 [P] [US5] Add `AppRoutes.settingsHowItWorks` + `AppRoutes.settingsPrivacy` constants in `lib/core/constants/app_routes.dart` and routes in the router.
- [X] T048 [P] [US5] In-app `HowItWorksPage` (no-server explainer) + `PrivacyPolicyPage` in `lib/features/settings/presentation/pages/` (localized).
- [X] T049 [US5] About section widget (version + tagline "Safe Send v1.0.0 · WebRTC P2P" + how-it-works/privacy nav rows + "Đánh giá ứng dụng") in `lib/features/settings/presentation/widgets/about_section.dart`; wire into `settings_page.dart`.
- [X] T050 [P] [US5] Tests: about-section widget test (version render from a fake `AppInfoService`); how-it-works + privacy page render tests.

**Checkpoint**: All 5 user stories functional.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T051 [P] ARB key parity check VI↔EN (all new settings/about/failure strings present in both, `@description` on each) in `lib/l10n/arb/`.
- [X] T052 Log-hygiene pass: grep `AppLogger`/transfer/notifier paths to confirm no device name, endpoint, or `senderName` is logged (Principle I).
- [X] T053 Reduce-Motion + a11y labels on the profile card, pickers, and toggles; platform-adaptive confirm for "clear endpoint" (Constitution VI/VII).
- [X] T054 Run gates: `dart format .` · `dart analyze lib test` (0) · `flutter test` (all green, prior 230 + new) · bloc-lint when available.
- [X] T055 Execute [quickstart.md](quickstart.md) CI-testable steps; update the deferred two-device-smoke + `pod install` banner status.
- [X] T056 [P] Update `.claude/claude-app/changelog.md` + `project-context.md` + `sdd-roadmap.md` (#010 → implemented) and `CLAUDE.md` stack entry on completion.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Ph1)**: no deps.
- **Foundational (Ph2)**: depends on Setup — **BLOCKS all stories**.
- **US1 (Ph3) / US2 (Ph4)** — both P1, the MVP: depend only on Foundational; independently testable. US1's manifest `senderName` (T019–T022) and US2's receive seams (T031–T033) both touch `ReceiveTransferCubit` → coordinate (do US1 first, then US2 layers on).
- **US3 (Ph5)**: depends on Foundational; T038 builds on the T013 provider.
- **US4 (Ph6)**: depends on Foundational; touches `SignalingClient` (isolated).
- **US5 (Ph7)**: depends on Foundational; fully isolated.
- **Polish (Ph8)**: after all targeted stories.

### Within Each Story
- Use cases / services (often [P]) → section widget → cross-feature wiring → tests.
- The `settings_page.dart` wiring tasks (T018/T030/T037/T044/T049) are sequential (same file).
- `ReceiveTransferCubit` tasks (T021, T031, T033) are sequential (same file).

### Parallel Opportunities
- Setup T002/T003 parallel.
- Foundational T004/T005 parallel; T015/T016 parallel after the repo/cubit exist.
- Across stories after Foundational: US3, US4, US5 are largely independent and can proceed in parallel; US1+US2 share `ReceiveTransferCubit` so serialize those touches.
- Service/use-case creation tasks marked [P] within a story (different files).

---

## Parallel Example: Foundational domain types

```bash
Task: "Create ThemePreference + LanguagePreference enums (T004)"
Task: "Create DeviceProfile helper (T005)"
# then T006 AppSettings, T007 interface (sequential — reference the enums)
```

## Parallel Example: US2 core services

```bash
Task: "PhotoLibraryPermissionService (T025)"
Task: "NotificationPermissionService (T026)"
Task: "GallerySaverService wrapping gal (T027)"
Task: "IncomingFileNotifier wrapping flutter_local_notifications (T028)"
```

---

## Implementation Strategy

### MVP First (US1 + US2 — both P1)
1. Phase 1 Setup → Phase 2 Foundational (CRITICAL).
2. Phase 3 US1 (device profile + manifest senderName).
3. Phase 4 US2 (toggles + receive behavior).
4. **STOP & VALIDATE**: Settings drives identity + incoming-file handling. Demo.

### Incremental Delivery
US3 (appearance/language) → US4 (advanced signaling) → US5 (about), each independently testable, then Polish.

---

## Notes
- [P] = different files, no incomplete-task deps. [Story] label maps to spec user stories.
- Inject Use Cases (not the repo) into Cubits where a use case exists; the app-wide `SettingsCubit` reads the repo stream (Constitution III).
- Commit after each task or logical group. Run `dart analyze` + targeted tests per task.
- The manifest `senderName` (T019) is the one protocol touch — keep it additive/versioned and re-run the loopback round-trip (Constitution VIII/XII).
