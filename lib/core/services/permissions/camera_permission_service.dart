import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera permission outcome, abstracted from the plugin so cubits depend on a
/// small core enum (not `permission_handler` types) and stay testable.
enum CameraPermissionStatus {
  /// The user granted camera access.
  granted,

  /// Denied, but the system prompt can still be shown (re-requestable).
  denied,

  /// Denied and the OS will no longer prompt — only Settings can re-enable it.
  permanentlyDenied,

  /// Blocked by a system policy (e.g. parental controls); not user-recoverable.
  restricted,
}

/// Thin seam over the camera runtime permission (#007 — the app's first).
abstract interface class CameraPermissionService {
  /// The current permission status without prompting.
  Future<CameraPermissionStatus> status();

  /// Request access, showing the system prompt if still askable.
  Future<CameraPermissionStatus> request();

  /// Open the OS app-settings page so a blocked permission can be re-enabled.
  Future<void> openSettings();
}

/// `permission_handler`-backed implementation.
@LazySingleton(as: CameraPermissionService)
class PermissionHandlerCameraService implements CameraPermissionService {
  @override
  Future<CameraPermissionStatus> status() async =>
      _map(await Permission.camera.status);

  @override
  Future<CameraPermissionStatus> request() async =>
      _map(await Permission.camera.request());

  @override
  Future<void> openSettings() async => openAppSettings();

  CameraPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return CameraPermissionStatus.granted;
    }
    if (s.isPermanentlyDenied) return CameraPermissionStatus.permanentlyDenied;
    if (s.isRestricted) return CameraPermissionStatus.restricted;
    return CameraPermissionStatus.denied;
  }
}
