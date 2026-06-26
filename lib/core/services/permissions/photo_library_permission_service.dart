import 'package:gal/gal.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

/// Thin seam over photo-library "add" access (#010), backed by `gal` which
/// handles the iOS/Android differences for *saving* media (Android 33+ scoped
/// MediaStore needs no permission; iOS uses add-only access). Used to gate the
/// "Lưu vào Thư viện" toggle (FR-010).
abstract interface class PhotoLibraryPermissionService {
  /// Whether the app may already add to the library (no prompt).
  Future<bool> hasAccess();

  /// Request add access, showing the system prompt if askable. Returns whether
  /// access is now granted.
  Future<bool> requestAccess();

  /// Open the OS app-settings page so a blocked permission can be re-enabled.
  Future<void> openSettings();
}

/// `gal`-backed implementation.
@LazySingleton(as: PhotoLibraryPermissionService)
class GalPhotoLibraryPermissionService
    implements PhotoLibraryPermissionService {
  @override
  Future<bool> hasAccess() => Gal.hasAccess();

  @override
  Future<bool> requestAccess() => Gal.requestAccess();

  @override
  Future<void> openSettings() async => openAppSettings();
}
