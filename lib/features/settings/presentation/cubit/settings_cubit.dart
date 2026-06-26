import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/signaling_endpoint_provider.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/core/services/permissions/notification_permission_service.dart';
import 'package:safe_send/core/services/permissions/photo_library_permission_service.dart';
import 'package:safe_send/core/services/signaling/signaling_diagnostics_service.dart';

/// App-wide settings state (#010). Registered `@lazySingleton` because it is the
/// single source of truth read by both `MaterialApp` (theme/locale, US3) and the
/// Settings page (FR-020). 4-state (`AppCubit<AppSettings>`): `loaded` carries
/// the live snapshot.
///
/// It depends on the core [SettingsRepository] service directly (not a wrapper
/// use case): all validation lives in the repository, so the cubit is a thin
/// reactive adapter + command forwarder — wrapping each pass-through setter in a
/// use case would be ceremony without behavior (Constitution XIII). Mutations do
/// not emit directly; the repository's [SettingsRepository.watch] stream is the
/// one path that updates state. Validation failures are returned to the caller
/// (for a toast) and never push this app-wide cubit into the error state, which
/// would blank the theme/locale.
@lazySingleton
class SettingsCubit extends AppCubit<AppSettings> {
  SettingsCubit(
    this._repo,
    this._photoPerm,
    this._notifPerm,
    this._endpointProvider,
    this._diagnostics,
  ) {
    emitLoaded(_repo.current);
    _sub = _repo.watch().listen(emitLoaded);
  }

  final SettingsRepository _repo;
  final PhotoLibraryPermissionService _photoPerm;
  final NotificationPermissionService _notifPerm;
  final SignalingEndpointProvider _endpointProvider;
  final SignalingDiagnosticsService _diagnostics;
  StreamSubscription<AppSettings>? _sub;

  /// The current snapshot (safe after construction).
  AppSettings get settings => _repo.current;

  Future<Result<void>> setDeviceName(String name) => _repo.setDeviceName(name);

  Future<Result<void>> setAutoReceive({required bool value}) =>
      _repo.setAutoReceive(value: value);

  /// Enabling requests photo-library access first; on denial the toggle stays
  /// OFF and a [AppFailure.permissionDenied] is returned for a toast + Open
  /// Settings (FR-010). Disabling always persists.
  Future<Result<void>> setSaveToLibrary({required bool value}) async {
    if (value && !await _photoPerm.requestAccess()) {
      return const Result.failure(AppFailure.permissionDenied());
    }
    return _repo.setSaveToLibrary(value: value);
  }

  /// Enabling requests notification permission first; same blocked-state
  /// contract as [setSaveToLibrary] (FR-010).
  Future<Result<void>> setNotifications({required bool value}) async {
    if (value) {
      final status = await _notifPerm.request();
      if (status != NotificationPermissionStatus.granted) {
        return const Result.failure(AppFailure.permissionDenied());
      }
    }
    return _repo.setNotifications(value: value);
  }

  /// Open the OS settings page (for a blocked photo/notification permission).
  Future<void> openPhotoSettings() => _photoPerm.openSettings();
  Future<void> openNotificationSettings() => _notifPerm.openSettings();

  Future<Result<void>> setTheme(ThemePreference value) => _repo.setTheme(value);

  Future<Result<void>> setLanguage(LanguagePreference value) =>
      _repo.setLanguage(value);

  Future<Result<void>> setSignalingOverride(Uri? value) =>
      _repo.setSignalingOverride(value);

  /// Probe the effective signaling endpoint (override ?? flavor default) for
  /// reachability (FR-015).
  Future<Result<void>> runDiagnostic() {
    final endpoint = _endpointProvider.effective();
    if (endpoint == null) {
      return Future.value(
        const Result.failure(AppFailure.signalingUnreachable()),
      );
    }
    return _diagnostics.probe(endpoint);
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
