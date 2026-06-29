import 'package:safe_send/core/config/signaling_endpoint_provider.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/core/services/media/gallery_saver_service.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';
import 'package:safe_send/core/services/permissions/notification_permission_service.dart';
import 'package:safe_send/core/services/permissions/photo_library_permission_service.dart';
import 'package:safe_send/core/services/signaling/signaling_diagnostics_service.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';

/// In-memory [SettingsRepository] for tests. Defaults mirror first-run (all
/// toggles OFF), so receive-flow behavior is unchanged unless a test opts in.
class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository([AppSettings? initial])
    : _snapshot = initial ?? const AppSettings(deviceName: 'Test Device');

  AppSettings _snapshot;

  @override
  Future<void> init() async {}

  @override
  AppSettings get current => _snapshot;

  @override
  Stream<AppSettings> watch() => Stream.value(_snapshot);

  @override
  Future<Result<void>> setDeviceName(String name) async {
    _snapshot = _snapshot.copyWith(deviceName: name);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setAutoReceive({required bool value}) async {
    _snapshot = _snapshot.copyWith(autoReceive: value);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setSaveToLibrary({required bool value}) async {
    _snapshot = _snapshot.copyWith(saveToLibrary: value);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setNotifications({required bool value}) async {
    _snapshot = _snapshot.copyWith(notifications: value);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setTheme(ThemePreference value) async {
    _snapshot = _snapshot.copyWith(theme: value);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setLanguage(LanguagePreference value) async {
    _snapshot = _snapshot.copyWith(language: value);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setSignalingOverride(Uri? value) async {
    _snapshot = _snapshot.copyWith(signalingOverride: value);
    return const Result.success(null);
  }
}

/// Records library-save calls without touching the OS.
class FakeGallerySaver implements GallerySaverService {
  final List<String> saved = [];

  @override
  Future<Result<void>> saveMedia(
    String filePath, {
    required bool isVideo,
  }) async {
    saved.add(filePath);
    return const Result.success(null);
  }
}

/// Records notification calls without touching the OS.
class FakeIncomingFileNotifier implements IncomingFileNotifier {
  int shown = 0;

  @override
  Future<void> init({void Function()? onTap}) async {}

  @override
  Future<void> showIncoming({required String senderName}) async => shown++;

  @override
  Future<void> scheduleKeepOpenReminder({
    required String title,
    required String body,
    int afterSeconds = 5,
  }) async {}

  @override
  Future<void> cancelKeepOpenReminder() async {}

  @override
  Future<bool> requestNotificationPermission() async => true;
}

/// Always-grant photo-library permission.
class FakePhotoLibraryPermission implements PhotoLibraryPermissionService {
  bool granted = true;

  @override
  Future<bool> hasAccess() async => granted;

  @override
  Future<bool> requestAccess() async => granted;

  @override
  Future<void> openSettings() async {}
}

/// Always-grant notification permission.
class FakeNotificationPermission implements NotificationPermissionService {
  NotificationPermissionStatus status0 = NotificationPermissionStatus.granted;

  @override
  Future<NotificationPermissionStatus> status() async => status0;

  @override
  Future<NotificationPermissionStatus> request() async => status0;

  @override
  Future<void> openSettings() async {}
}

/// Returns a fixed effective endpoint.
class FakeSignalingEndpointProvider implements SignalingEndpointProvider {
  FakeSignalingEndpointProvider([this.uri]);

  Uri? uri;

  @override
  Uri? effective() => uri;
}

/// Reports a configurable reachability outcome.
class FakeSignalingDiagnostics implements SignalingDiagnosticsService {
  bool reachable = true;

  @override
  Future<Result<void>> probe(
    Uri endpoint, {
    Duration timeout = Duration.zero,
  }) async => reachable
      ? const Result.success(null)
      : const Result.failure(AppFailure.signalingUnreachable());
}

/// Construct a [SettingsCubit] with fakes; override only what a test needs.
SettingsCubit makeSettingsCubit({
  SettingsRepository? repo,
  PhotoLibraryPermissionService? photo,
  NotificationPermissionService? notif,
  SignalingEndpointProvider? endpoint,
  SignalingDiagnosticsService? diagnostics,
}) => SettingsCubit(
  repo ?? FakeSettingsRepository(),
  photo ?? FakePhotoLibraryPermission(),
  notif ?? FakeNotificationPermission(),
  endpoint ?? FakeSignalingEndpointProvider(),
  diagnostics ?? FakeSignalingDiagnostics(),
);
