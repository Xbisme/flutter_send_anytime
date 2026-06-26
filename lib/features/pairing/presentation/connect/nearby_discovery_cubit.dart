import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';

/// The loaded payload of [NearbyDiscoveryCubit] — either a live device list or a
/// permission-blocked surface (distinct from an empty list, FR-012/016).
sealed class NearbyBrowse {
  const NearbyBrowse();
}

/// Browsing is active; [devices] is the live (possibly empty) discovered list.
class NearbyBrowsing extends NearbyBrowse {
  const NearbyBrowsing(this.devices);

  final List<NearbyDevice> devices;
}

/// The nearby permission is denied; [permanent] drives the Open-Settings path.
class NearbyBrowseBlocked extends NearbyBrowse {
  const NearbyBrowseBlocked({required this.permanent});

  final bool permanent;
}

/// Drives the receiver's nearby browse surface (#009, US1): ensures permission,
/// then projects the discovery stream into a live [NearbyDevice] list. Tapping a
/// device is handled by the Connect hub (reuses the existing join path).
@injectable
class NearbyDiscoveryCubit extends AppCubit<NearbyBrowse> {
  NearbyDiscoveryCubit(this._discovery, this._permission);

  final NearbyDiscoveryService _discovery;
  final NearbyPermissionService _permission;

  StreamSubscription<List<NearbyDevice>>? _sub;

  /// Request permission (FR-011) then begin browsing. No advertising/browsing
  /// happens before the permission resolves (SC-005).
  Future<void> start() async {
    emitLoading();
    final status = await _permission.ensure();
    if (status != NearbyPermissionStatus.granted) {
      emitLoaded(
        NearbyBrowseBlocked(
          permanent: status == NearbyPermissionStatus.permanentlyDenied,
        ),
      );
      return;
    }
    emitLoaded(const NearbyBrowsing([]));
    await _sub?.cancel();
    _sub = _discovery.discover().listen(
      (devices) => emitLoaded(NearbyBrowsing(devices)),
      onError: (Object _) => emitError(const AppFailure.networkError()),
    );
  }

  /// Stop browsing (tab left / app backgrounded — FR-005) while keeping the
  /// cubit alive so [start] can resume.
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _discovery.stopDiscover();
  }

  /// Open the OS settings page from the permission-blocked state.
  Future<void> openSettings() => _permission.openSettings();

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
