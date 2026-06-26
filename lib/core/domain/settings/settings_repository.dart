import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';

/// The single cross-feature contract for user preferences (#010, FR-020).
///
/// Lives in `core/domain` so any feature (Receive, app root, pairing, history)
/// can read it without importing the `shared_preferences`-backed impl
/// (Constitution XI). [init] is awaited in bootstrap before the first frame so
/// [current] is always safe to read synchronously; [watch] drives reactive
/// surfaces (theme/locale, the Settings page).
abstract interface class SettingsRepository {
  /// Load persisted values into the in-memory snapshot. Idempotent; generates
  /// and persists a default device name on first run. Call once in bootstrap.
  Future<void> init();

  /// The current snapshot (valid after [init]).
  AppSettings get current;

  /// Broadcast stream emitting the new snapshot after every change.
  Stream<AppSettings> watch();

  /// Set the device name. Validates: trimmed, non-empty, ≤30 chars (FR-002).
  Future<Result<void>> setDeviceName(String name);

  /// Toggle foreground auto-receive (FR-007).
  Future<Result<void>> setAutoReceive({required bool value});

  /// Toggle save-received-media-to-library (FR-008).
  Future<Result<void>> setSaveToLibrary({required bool value});

  /// Toggle incoming-file notifications (FR-009).
  Future<Result<void>> setNotifications({required bool value});

  /// Set the theme mode (FR-011).
  Future<Result<void>> setTheme(ThemePreference value);

  /// Set the language (FR-012).
  Future<Result<void>> setLanguage(LanguagePreference value);

  /// Set/clear the signaling endpoint override. `null` restores the per-flavor
  /// default. Validates scheme: `wss` any flavor, `ws` dev-only (FR-014).
  Future<Result<void>> setSignalingOverride(Uri? value);
}
