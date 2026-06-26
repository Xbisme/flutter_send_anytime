import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/settings/device_profile.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';

part 'app_settings.freezed.dart';

/// Immutable snapshot of every user preference (#010) — the single source of
/// truth exposed by `SettingsRepository`. Persisted locally only (no cloud,
/// FR-019). Defaults here are the documented first-run values (FR-021); the
/// repository fills [deviceName] with a generated default on first init.
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    required String deviceName,
    @Default(false) bool autoReceive,
    @Default(false) bool saveToLibrary,
    @Default(false) bool notifications,
    @Default(ThemePreference.system) ThemePreference theme,
    @Default(LanguagePreference.system) LanguagePreference language,
    @Default(null) Uri? signalingOverride,
  }) = _AppSettings;

  const AppSettings._();

  /// The device identity (name + avatar initial) shown to peers.
  DeviceProfile get profile => DeviceProfile(deviceName);
}
