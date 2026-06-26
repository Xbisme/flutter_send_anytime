import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';

/// The loaded payload of [NearbyAdvertiseCubit] — advertising the live code, or
/// permission-blocked.
sealed class NearbyAdvertise {
  const NearbyAdvertise();
}

/// The device is advertising the live hosting [code] on the local network.
class NearbyAdvertiseActive extends NearbyAdvertise {
  const NearbyAdvertiseActive(this.code);

  final String code;
}

/// The nearby permission is denied; [permanent] drives the Open-Settings path.
class NearbyAdvertiseBlocked extends NearbyAdvertise {
  const NearbyAdvertiseBlocked({required this.permanent});

  final bool permanent;
}

/// Drives the sender's "Gần đây" tab advertising (#009, US2): ensures
/// permission, then advertises the **live #003 hosting code** over mDNS. Never
/// generates a code — it reuses the existing hosting session (FR-009).
@injectable
class NearbyAdvertiseCubit extends AppCubit<NearbyAdvertise> {
  NearbyAdvertiseCubit(this._discovery, this._permission);

  final NearbyDiscoveryService _discovery;
  final NearbyPermissionService _permission;

  /// Request permission (FR-011) then advertise [code]. No broadcast happens
  /// before the permission resolves (SC-005).
  Future<void> start({
    required String code,
    required String displayName,
  }) async {
    emitLoading();
    final status = await _permission.ensure();
    if (status != NearbyPermissionStatus.granted) {
      emitLoaded(
        NearbyAdvertiseBlocked(
          permanent: status == NearbyPermissionStatus.permanentlyDenied,
        ),
      );
      return;
    }
    final result = await _discovery.advertise(
      code: code,
      displayName: displayName,
    );
    result.fold(
      (_) => emitLoaded(NearbyAdvertiseActive(code)),
      emitError,
    );
  }

  /// Stop advertising (tab left / app backgrounded — FR-005).
  Future<void> stop() => _discovery.stopAdvertise();

  /// Open the OS settings page from the permission-blocked state.
  Future<void> openSettings() => _permission.openSettings();

  @override
  Future<void> close() async {
    await stop();
    return super.close();
  }
}
