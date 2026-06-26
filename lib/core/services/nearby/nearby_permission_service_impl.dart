import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';

/// `permission_handler`-backed implementation (#009). Only Android exposes a
/// runtime gate (`NEARBY_WIFI_DEVICES`, API 33+); iOS is governed by the OS
/// Local Network prompt that fires on first mDNS use, so it reports `granted`.
@LazySingleton(as: NearbyPermissionService)
class PermissionHandlerNearbyService implements NearbyPermissionService {
  @override
  Future<NearbyPermissionStatus> ensure() async {
    if (!Platform.isAndroid) return NearbyPermissionStatus.granted;
    return _map(await Permission.nearbyWifiDevices.request());
  }

  @override
  Future<void> openSettings() async => openAppSettings();

  NearbyPermissionStatus _map(PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) {
      return NearbyPermissionStatus.granted;
    }
    if (s.isPermanentlyDenied || s.isRestricted) {
      return NearbyPermissionStatus.permanentlyDenied;
    }
    return NearbyPermissionStatus.denied;
  }
}
