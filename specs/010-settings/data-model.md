# Phase 1 Data Model: Settings & Preferences (#010)

All types are in-memory/value objects persisted via `shared_preferences` (no SQL schema). Freezed for immutability (Constitution III/IV).

---

## Entity: `AppSettings` — `lib/core/domain/settings/app_settings.dart`

Immutable snapshot of every preference. The single source of truth surfaced by `SettingsRepository.current` and `watch()`.

| Field | Type | Default | Persisted key | Notes |
|---|---|---|---|---|
| `deviceName` | `String` | generated `Safe Send · XXXX` (once, then persisted) | `settings.deviceName` | trimmed, non-empty, ≤30 chars unicode (FR-002) |
| `autoReceive` | `bool` | `false` | `settings.autoReceive` | foreground skip-tap (FR-007) |
| `saveToLibrary` | `bool` | `false` | `settings.saveToLibrary` | media→photo library (FR-008); needs photo perm |
| `notifications` | `bool` | `false` | `settings.notifications` | incoming-file local notif (FR-009); needs notif perm |
| `theme` | `ThemePreference` | `system` | `settings.theme` | FR-011 |
| `language` | `LanguagePreference` | `system` | `settings.language` | FR-012 |
| `signalingOverride` | `Uri?` | `null` | `settings.signalingOverride` | null ⇒ flavor default (FR-013) |

**Validation rules**
- `deviceName`: reject empty/whitespace-only-after-trim or length > 30; keep prior value on reject (FR-002). Avatar initial derived from first non-whitespace grapheme (display-only, `DeviceProfile`).
- `signalingOverride`: parse as `Uri`; accept scheme `wss` in any flavor; accept `ws` **only** when `AppFlavor.isDev`; reject otherwise (FR-014).
- Booleans/enums: invalid stored value ⇒ fall back to documented default (FR-021).

**Derived**: `DeviceProfile { String name; String initial }` (helper in `device_profile.dart`) for the profile card — no separate persistence.

---

## Enum: `ThemePreference` — `lib/core/domain/settings/preference_enums.dart`

`light | dark | system` → mapped to Flutter `ThemeMode` in `app.dart` (`system` default).

## Enum: `LanguagePreference`

`vietnamese | english | system` → mapped to `Locale?` (`vietnamese→Locale('vi')`, `english→Locale('en')`, `system→null` keeps the existing VI-fallback resolution).

---

## Contract: `SettingsRepository` — `lib/core/domain/settings/settings_repository.dart`

```dart
abstract interface class SettingsRepository {
  Future<void> init();                 // load all keys into the snapshot (called in bootstrap)
  AppSettings get current;             // sync snapshot (first frame safe)
  Stream<AppSettings> watch();         // broadcast; emits on every change

  Future<Result<void>> setDeviceName(String name);          // validates (FR-002)
  Future<Result<void>> setAutoReceive(bool value);
  Future<Result<void>> setSaveToLibrary(bool value);
  Future<Result<void>> setNotifications(bool value);
  Future<Result<void>> setTheme(ThemePreference value);
  Future<Result<void>> setLanguage(LanguagePreference value);
  Future<Result<void>> setSignalingOverride(Uri? value);    // validates scheme/flavor (FR-014)
}
```

Impl: `SharedPreferencesSettingsRepository` (`core/data/`, `@LazySingleton(as: SettingsRepository)`). Setters return `Result<void>` (Principle V) — validation failures map to `AppFailure`.

---

## Core services (interfaces in `core/`, `@LazySingleton` impls)

| Service | Location | Responsibility |
|---|---|---|
| `SignalingEndpointProvider` | `core/config/` | `Uri effective()` = `settings.signalingOverride ?? appConfig.signalingEndpoint` |
| `SignalingDiagnosticsService` | `core/services/signaling/` | `Future<Result<void>> probe(Uri)` — ws connect + timeout (FR-015) |
| `PhotoLibraryPermissionService` | `core/services/permissions/` | `status()/request()/openSettings()` (mirror CameraPermissionService) |
| `NotificationPermissionService` | `core/services/permissions/` | same shape |
| `GallerySaverService` | `core/services/media/` | `Future<Result<void>> saveMedia(String path, {required bool isVideo})` (gal) |
| `IncomingFileNotifier` | `core/services/notifications/` | `init()` + `Future<void> showIncoming({required String senderName})` |
| `AppInfoService` | `core/services/` (or feature) | version string from package_info_plus (FR-016) |

---

## Transfer manifest extension (additive, versioned)

`core/domain/transfer` manifest gains one **optional** field:

| Field | Type | Default | Notes |
|---|---|---|---|
| `senderName` | `String?` | `null` | sender's `deviceName`; receiver maps to accept-prompt `senderLabel` + history `peerLabel`; empty/absent ⇒ existing generic localized label. Backward-compatible (older senders omit). MUST NOT be logged (Principle I). |

State transition impact: none — the existing `idle→connecting→handshaking→transferring→done|failed|cancelled` machine is unchanged; `senderName` is read at the handshaking/manifest step only.

---

## AppFailure additions (`core/domain`, Principle V)

| Variant | When | Localized message |
|---|---|---|
| `invalidSignalingEndpoint` (or reuse `unknown` w/ message) | override fails scheme/flavor validation (FR-014) | "Địa chỉ máy chủ không hợp lệ" |
| reuse `permissionDenied` | photo-library / notification permission denied (FR-010) | existing mapping + Open Settings |
| reuse `networkError` / `signalingUnreachable` | diagnostic probe fails (FR-015) | "Không kết nối được máy chủ" |

---

## Cubit state: `SettingsState` — `features/settings/presentation/cubit/`

4-state freezed (Constitution III): `initial → loading → loaded(AppSettings data, {AppVersion version, save/notify permission hints}) → error(AppFailure)`. The `loaded` state carries the `AppSettings` snapshot + the resolved app version + transient permission/diagnostic feedback. App-wide `@lazySingleton`; `app.dart` reads `themeMode`/`locale` from `loaded.data`.
