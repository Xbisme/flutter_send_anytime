import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Notification permission outcome, abstracted from the plugin (mirror of the
/// #007 camera seam) so cubits depend on a small core enum.
enum NotificationPermissionStatus {
  /// The user granted notifications.
  granted,

  /// Denied but re-requestable.
  denied,

  /// Denied permanently — only Settings can re-enable it.
  permanentlyDenied,
}

/// Thin seam over the notifications runtime permission (#010, Android 13+;
/// iOS authorization). Gates the "Thông báo" toggle (FR-010).
abstract interface class NotificationPermissionService {
  /// Current status without prompting.
  Future<NotificationPermissionStatus> status();

  /// Request access, showing the system prompt if still askable.
  Future<NotificationPermissionStatus> request();

  /// Open the OS app-settings page so a blocked permission can be re-enabled.
  Future<void> openSettings();
}

/// `permission_handler`-backed implementation.
@LazySingleton(as: NotificationPermissionService)
class PermissionHandlerNotificationService
    implements NotificationPermissionService {
  @override
  Future<NotificationPermissionStatus> status() async =>
      _map(await Permission.notification.status);

  @override
  Future<NotificationPermissionStatus> request() async =>
      _map(await Permission.notification.request());

  @override
  Future<void> openSettings() async => openAppSettings();

  NotificationPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return NotificationPermissionStatus.granted;
    }
    if (s.isPermanentlyDenied) {
      return NotificationPermissionStatus.permanentlyDenied;
    }
    return NotificationPermissionStatus.denied;
  }
}
