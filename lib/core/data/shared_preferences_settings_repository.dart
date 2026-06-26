import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// `shared_preferences`-backed [SettingsRepository] (#010). Loads all keys into
/// an in-memory [AppSettings] snapshot on [init] (so the first frame reads
/// theme/locale synchronously, no flash), and emits on a broadcast stream after
/// every change. Stores locally only (FR-019). Never logs the device name or
/// endpoint (Principle I).
@LazySingleton(as: SettingsRepository)
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._config);

  final AppConfig _config;

  /// Max device-name length in code points (FR-002, clarified ≤30).
  static const int maxDeviceNameLength = 30;

  static const _kDeviceName = 'settings.deviceName';
  static const _kAutoReceive = 'settings.autoReceive';
  static const _kSaveToLibrary = 'settings.saveToLibrary';
  static const _kNotifications = 'settings.notifications';
  static const _kTheme = 'settings.theme';
  static const _kLanguage = 'settings.language';
  static const _kSignalingOverride = 'settings.signalingOverride';

  SharedPreferences? _prefs;
  // Safe placeholder before [init] runs (defensive; bootstrap awaits init so the
  // real first frame already has persisted values).
  AppSettings _snapshot = const AppSettings(deviceName: 'Safe Send');
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Future<void> init() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();

    var deviceName = prefs.getString(_kDeviceName);
    if (deviceName == null || deviceName.trim().isEmpty) {
      deviceName = _generateDefaultName();
      await prefs.setString(_kDeviceName, deviceName);
    }

    final overrideRaw = prefs.getString(_kSignalingOverride);

    _snapshot = AppSettings(
      deviceName: deviceName,
      autoReceive: prefs.getBool(_kAutoReceive) ?? false,
      saveToLibrary: prefs.getBool(_kSaveToLibrary) ?? false,
      notifications: prefs.getBool(_kNotifications) ?? false,
      theme: _decodeEnum(
        prefs.getString(_kTheme),
        ThemePreference.values,
        ThemePreference.system,
      ),
      language: _decodeEnum(
        prefs.getString(_kLanguage),
        LanguagePreference.values,
        LanguagePreference.system,
      ),
      signalingOverride: overrideRaw == null ? null : Uri.tryParse(overrideRaw),
    );
  }

  @override
  AppSettings get current => _snapshot;

  @override
  Stream<AppSettings> watch() => _controller.stream;

  @override
  Future<Result<void>> setDeviceName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.runes.length > maxDeviceNameLength) {
      return const Result.failure(AppFailure.unexpected());
    }
    await _prefs!.setString(_kDeviceName, trimmed);
    return _emit(_snapshot.copyWith(deviceName: trimmed));
  }

  @override
  Future<Result<void>> setAutoReceive({required bool value}) async {
    await _prefs!.setBool(_kAutoReceive, value);
    return _emit(_snapshot.copyWith(autoReceive: value));
  }

  @override
  Future<Result<void>> setSaveToLibrary({required bool value}) async {
    await _prefs!.setBool(_kSaveToLibrary, value);
    return _emit(_snapshot.copyWith(saveToLibrary: value));
  }

  @override
  Future<Result<void>> setNotifications({required bool value}) async {
    await _prefs!.setBool(_kNotifications, value);
    return _emit(_snapshot.copyWith(notifications: value));
  }

  @override
  Future<Result<void>> setTheme(ThemePreference value) async {
    await _prefs!.setString(_kTheme, value.name);
    return _emit(_snapshot.copyWith(theme: value));
  }

  @override
  Future<Result<void>> setLanguage(LanguagePreference value) async {
    await _prefs!.setString(_kLanguage, value.name);
    return _emit(_snapshot.copyWith(language: value));
  }

  @override
  Future<Result<void>> setSignalingOverride(Uri? value) async {
    if (value == null) {
      await _prefs!.remove(_kSignalingOverride);
      return _emit(_snapshot.copyWith(signalingOverride: null));
    }
    if (!_isValidEndpoint(value)) {
      return const Result.failure(AppFailure.invalidSignalingEndpoint());
    }
    await _prefs!.setString(_kSignalingOverride, value.toString());
    return _emit(_snapshot.copyWith(signalingOverride: value));
  }

  /// Accept `wss` in any flavor; `ws` only in dev; reject everything else.
  bool _isValidEndpoint(Uri uri) {
    if (uri.host.isEmpty) return false;
    return switch (uri.scheme) {
      'wss' => true,
      'ws' => _config.flavor.isDev,
      _ => false,
    };
  }

  Result<void> _emit(AppSettings next) {
    _snapshot = next;
    _controller.add(next);
    return const Result.success(null);
  }

  String _generateDefaultName() =>
      'Safe Send · ${const Uuid().v4().substring(0, 4).toUpperCase()}';

  T _decodeEnum<T extends Enum>(String? raw, List<T> values, T fallback) {
    if (raw == null) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
