# Contract: Settings Repository & Services (#010)

The app's only external "interface" here is the **internal cross-feature contract** other features read (Constitution XI). No network API. This file pins the contract so Send/Receive/Home/History/App-root and the Settings feature agree.

## `SettingsRepository` (core/domain/settings)

```dart
abstract interface class SettingsRepository {
  Future<void> init();
  AppSettings get current;
  Stream<AppSettings> watch();

  Future<Result<void>> setDeviceName(String name);
  Future<Result<void>> setAutoReceive(bool value);
  Future<Result<void>> setSaveToLibrary(bool value);
  Future<Result<void>> setNotifications(bool value);
  Future<Result<void>> setTheme(ThemePreference value);
  Future<Result<void>> setLanguage(LanguagePreference value);
  Future<Result<void>> setSignalingOverride(Uri? value);
}
```

**Guarantees**
- `init()` is idempotent and completes before `runApp` (bootstrap). After it, `current` never throws and reflects persisted values or documented defaults.
- Every successful setter (a) persists, (b) updates `current`, (c) emits the new snapshot on `watch()` — in that order.
- `watch()` is a broadcast stream; multiple consumers (app root + settings page + receive cubit) may listen.
- Validating setters (`setDeviceName`, `setSignalingOverride`) return `Failure(AppFailure)` and **do not mutate** state on invalid input.

## Consumers (who reads what — the contract surface)

| Consumer | Reads | Via |
|---|---|---|
| `app.dart` (root) | `theme`, `language` | `SettingsCubit` (watches repo) → `MaterialApp.themeMode` / `locale` |
| `ReceiveTransferCubit` | `autoReceive`, `notifications`, peer `senderName` | injected `SettingsRepository.current` + lifecycle |
| Receive terminal/per-file branch | `saveToLibrary` | injected `GallerySaverService` (gated by setting) |
| `NearbyAdvertisePanel` (#009) | `deviceName` | injected `SettingsRepository.current` (replaces inline UUID) |
| History record mapper (#006) | `senderName` from manifest | populates `peerLabel` (was empty) |
| `SignalingClient.create` (#003) | effective endpoint | `SignalingEndpointProvider.effective()` |

## Service contracts

```dart
// core/config
abstract interface class SignalingEndpointProvider { Uri effective(); }

// core/services/signaling
abstract interface class SignalingDiagnosticsService {
  Future<Result<void>> probe(Uri endpoint, {Duration timeout});
}

// core/services/permissions  (mirror CameraPermissionService from #007)
enum PrefPermissionStatus { granted, denied, permanentlyDenied, restricted }
abstract interface class PhotoLibraryPermissionService {
  Future<PrefPermissionStatus> status();
  Future<PrefPermissionStatus> request();
  Future<void> openSettings();
}
abstract interface class NotificationPermissionService { /* same shape */ }

// core/services/media
abstract interface class GallerySaverService {
  Future<Result<void>> saveMedia(String filePath, {required bool isVideo});
}

// core/services/notifications
abstract interface class IncomingFileNotifier {
  Future<void> init();
  Future<void> showIncoming({required String senderName});
}
```

**Validation contract — `setSignalingOverride`**
- `null` → clears override (restores flavor default). Success.
- scheme `wss` → accept (any flavor).
- scheme `ws` → accept only if `AppFlavor.isDev`; else `Failure(invalidSignalingEndpoint)`.
- any other scheme / unparseable → `Failure(invalidSignalingEndpoint)`.

**Validation contract — `setDeviceName`**
- trim; reject empty or length>30 → `Failure(...)`, no mutation.
- else persist trimmed value.
