// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:safe_send/core/config/app_config.dart' as _i132;
import 'package:safe_send/core/config/signaling_endpoint_provider.dart'
    as _i795;
import 'package:safe_send/core/data/database/app_database.dart' as _i196;
import 'package:safe_send/core/data/shared_preferences_settings_repository.dart'
    as _i329;
import 'package:safe_send/core/data/transfer_history_repository_impl.dart'
    as _i835;
import 'package:safe_send/core/di/database_module.dart' as _i206;
import 'package:safe_send/core/domain/history/transfer_history_repository.dart'
    as _i1016;
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart'
    as _i1032;
import 'package:safe_send/core/domain/settings/settings_repository.dart'
    as _i656;
import 'package:safe_send/core/services/app_info_service.dart' as _i118;
import 'package:safe_send/core/services/app_review_service.dart' as _i966;
import 'package:safe_send/core/services/background/background_execution_service.dart'
    as _i257;
import 'package:safe_send/core/services/background/background_module.dart'
    as _i762;
import 'package:safe_send/core/services/background/background_surface_controller.dart'
    as _i154;
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart'
    as _i575;
import 'package:safe_send/core/services/deeplink/deep_link_service.dart'
    as _i572;
import 'package:safe_send/core/services/deeplink/deep_link_service_impl.dart'
    as _i1;
import 'package:safe_send/core/services/file/file_picker_service.dart'
    as _i1069;
import 'package:safe_send/core/services/file/file_picker_service_impl.dart'
    as _i661;
import 'package:safe_send/core/services/file/received_files_service.dart'
    as _i58;
import 'package:safe_send/core/services/file/received_files_service_impl.dart'
    as _i423;
import 'package:safe_send/core/services/media/gallery_saver_service.dart'
    as _i206;
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart'
    as _i306;
import 'package:safe_send/core/services/nearby/nearby_discovery_service_impl.dart'
    as _i568;
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart'
    as _i532;
import 'package:safe_send/core/services/nearby/nearby_permission_service_impl.dart'
    as _i834;
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart'
    as _i853;
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart'
    as _i639;
import 'package:safe_send/core/services/permissions/camera_permission_service.dart'
    as _i522;
import 'package:safe_send/core/services/permissions/notification_permission_service.dart'
    as _i443;
import 'package:safe_send/core/services/permissions/photo_library_permission_service.dart'
    as _i641;
import 'package:safe_send/core/services/signaling/signaling_client.dart' as _i0;
import 'package:safe_send/core/services/signaling/signaling_diagnostics_service.dart'
    as _i190;
import 'package:safe_send/core/services/transport/data_transport.dart' as _i547;
import 'package:safe_send/core/services/transport/transfer_engine.dart'
    as _i953;
import 'package:safe_send/core/services/transport/webrtc_peer_connector.dart'
    as _i603;
import 'package:safe_send/features/history/domain/usecases/clear_history_usecase.dart'
    as _i359;
import 'package:safe_send/features/history/domain/usecases/delete_record_usecase.dart'
    as _i186;
import 'package:safe_send/features/history/domain/usecases/get_history_detail_usecase.dart'
    as _i646;
import 'package:safe_send/features/history/domain/usecases/resend_availability_usecase.dart'
    as _i671;
import 'package:safe_send/features/history/domain/usecases/watch_history_usecase.dart'
    as _i951;
import 'package:safe_send/features/history/presentation/cubit/history_cubit.dart'
    as _i560;
import 'package:safe_send/features/home/domain/usecases/watch_home_dashboard_usecase.dart'
    as _i872;
import 'package:safe_send/features/home/domain/usecases/watch_media_items_usecase.dart'
    as _i206;
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart'
    as _i511;
import 'package:safe_send/features/home/presentation/cubit/see_all_cubit.dart'
    as _i807;
import 'package:safe_send/features/pairing/data/pairing_repository_impl.dart'
    as _i181;
import 'package:safe_send/features/pairing/domain/pairing_repository.dart'
    as _i312;
import 'package:safe_send/features/pairing/domain/usecases/host_session_usecase.dart'
    as _i825;
import 'package:safe_send/features/pairing/domain/usecases/join_session_usecase.dart'
    as _i855;
import 'package:safe_send/features/pairing/presentation/connect/nearby_advertise_cubit.dart'
    as _i284;
import 'package:safe_send/features/pairing/presentation/connect/nearby_discovery_cubit.dart'
    as _i688;
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart'
    as _i964;
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart'
    as _i103;
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart'
    as _i590;
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart'
    as _i67;
import 'package:safe_send/features/send/domain/usecases/pick_files_usecase.dart'
    as _i36;
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart'
    as _i343;
import 'package:safe_send/features/send/presentation/cubit/send_selection_cubit.dart'
    as _i353;
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart'
    as _i259;
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart'
    as _i1071;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final databaseModule = _$DatabaseModule();
    final backgroundModule = _$BackgroundModule();
    gh.factory<_i671.ResendAvailabilityUseCase>(
      () => const _i671.ResendAvailabilityUseCase(),
    );
    gh.lazySingleton<_i196.AppDatabase>(() => databaseModule.appDatabase);
    gh.lazySingleton<_i572.DeepLinkService>(() => _i1.DeepLinkServiceImpl());
    gh.lazySingleton<_i206.GallerySaverService>(
      () => _i206.GalGallerySaverService(),
    );
    gh.lazySingleton<_i443.NotificationPermissionService>(
      () => _i443.PermissionHandlerNotificationService(),
    );
    gh.lazySingleton<_i966.AppReviewService>(() => _i966.InAppReviewService());
    gh.lazySingleton<_i641.PhotoLibraryPermissionService>(
      () => _i641.GalPhotoLibraryPermissionService(),
    );
    gh.lazySingleton<_i118.AppInfoService>(
      () => _i118.PackageInfoAppInfoService(),
    );
    gh.lazySingleton<_i522.CameraPermissionService>(
      () => _i522.PermissionHandlerCameraService(),
    );
    gh.lazySingleton<_i639.ActiveHostingRegistry>(
      () => _i639.ActiveHostingRegistryImpl(),
    );
    gh.lazySingleton<_i306.NearbyDiscoveryService>(
      () => _i568.NsdNearbyDiscoveryService(),
    );
    gh.lazySingleton<_i58.ReceivedFilesService>(
      () => _i423.ReceivedFilesServiceImpl(),
    );
    gh.lazySingleton<_i547.PeerConnector>(() => _i603.WebRtcPeerConnector());
    gh.lazySingleton<_i257.BackgroundExecutionService>(
      () => _i257.IosBackgroundExecutionService(),
    );
    gh.lazySingleton<_i532.NearbyPermissionService>(
      () => _i834.PermissionHandlerNearbyService(),
    );
    gh.lazySingleton<_i190.SignalingDiagnosticsService>(
      () => _i190.WebSocketSignalingDiagnostics(),
    );
    gh.factory<_i1069.FilePickerService>(
      () => const _i661.FilePickerServiceImpl(),
    );
    gh.lazySingleton<_i853.IncomingFileNotifier>(
      () => _i853.FlnIncomingFileNotifier(),
    );
    gh.lazySingleton<_i154.BackgroundSurfaceController>(
      () => backgroundModule.surfaceController(gh<_i132.AppConfig>()),
    );
    gh.lazySingleton<_i656.SettingsRepository>(
      () => _i329.SharedPreferencesSettingsRepository(gh<_i132.AppConfig>()),
    );
    gh.lazySingleton<_i1016.TransferHistoryRepository>(
      () => _i835.TransferHistoryRepositoryImpl(gh<_i196.AppDatabase>()),
    );
    gh.factory<_i1032.RecordTransferUseCase>(
      () =>
          _i1032.RecordTransferUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i359.ClearHistoryUseCase>(
      () => _i359.ClearHistoryUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i186.DeleteRecordUseCase>(
      () => _i186.DeleteRecordUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i646.GetHistoryDetailUseCase>(
      () =>
          _i646.GetHistoryDetailUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i951.WatchHistoryUseCase>(
      () => _i951.WatchHistoryUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i872.WatchHomeDashboardUseCase>(
      () => _i872.WatchHomeDashboardUseCase(
        gh<_i1016.TransferHistoryRepository>(),
      ),
    );
    gh.factory<_i206.WatchMediaItemsUseCase>(
      () =>
          _i206.WatchMediaItemsUseCase(gh<_i1016.TransferHistoryRepository>()),
    );
    gh.factory<_i284.NearbyAdvertiseCubit>(
      () => _i284.NearbyAdvertiseCubit(
        gh<_i306.NearbyDiscoveryService>(),
        gh<_i532.NearbyPermissionService>(),
      ),
    );
    gh.factory<_i688.NearbyDiscoveryCubit>(
      () => _i688.NearbyDiscoveryCubit(
        gh<_i306.NearbyDiscoveryService>(),
        gh<_i532.NearbyPermissionService>(),
      ),
    );
    gh.factory<_i103.QrScanCubit>(
      () => _i103.QrScanCubit(gh<_i522.CameraPermissionService>()),
    );
    gh.factory<_i807.SeeAllCubit>(
      () => _i807.SeeAllCubit(gh<_i206.WatchMediaItemsUseCase>()),
    );
    gh.factory<_i511.HomeCubit>(
      () => _i511.HomeCubit(gh<_i872.WatchHomeDashboardUseCase>()),
    );
    gh.factory<_i953.TransferEngine>(
      () => _i953.TransferEngine(
        gh<_i547.PeerConnector>(),
        gh<_i132.AppConfig>(),
      ),
    );
    gh.factory<_i36.PickFilesUseCase>(
      () => _i36.PickFilesUseCase(gh<_i1069.FilePickerService>()),
    );
    gh.factory<_i590.StartReceiveUseCase>(
      () => _i590.StartReceiveUseCase(
        gh<_i953.TransferEngine>(),
        gh<_i58.ReceivedFilesService>(),
      ),
    );
    gh.factory<_i560.HistoryCubit>(
      () => _i560.HistoryCubit(gh<_i951.WatchHistoryUseCase>()),
    );
    gh.lazySingleton<_i575.BackgroundTransferCoordinator>(
      () => _i575.BackgroundTransferCoordinator(
        gh<_i154.BackgroundSurfaceController>(),
        gh<_i853.IncomingFileNotifier>(),
        gh<_i257.BackgroundExecutionService>(),
      ),
      dispose: (i) => i.dispose(),
    );
    gh.factory<_i67.ReceiveTransferCubit>(
      () => _i67.ReceiveTransferCubit(
        gh<_i590.StartReceiveUseCase>(),
        gh<_i1032.RecordTransferUseCase>(),
        gh<_i656.SettingsRepository>(),
        gh<_i206.GallerySaverService>(),
        gh<_i853.IncomingFileNotifier>(),
      ),
    );
    gh.lazySingleton<_i795.SignalingEndpointProvider>(
      () => _i795.DefaultSignalingEndpointProvider(
        gh<_i132.AppConfig>(),
        gh<_i656.SettingsRepository>(),
      ),
    );
    gh.factory<_i0.SignalingClient>(
      () => _i0.SignalingClient.create(
        gh<_i132.AppConfig>(),
        gh<_i795.SignalingEndpointProvider>(),
      ),
    );
    gh.lazySingleton<_i1071.SettingsCubit>(
      () => _i1071.SettingsCubit(
        gh<_i656.SettingsRepository>(),
        gh<_i641.PhotoLibraryPermissionService>(),
        gh<_i443.NotificationPermissionService>(),
        gh<_i795.SignalingEndpointProvider>(),
        gh<_i190.SignalingDiagnosticsService>(),
      ),
    );
    gh.factory<_i353.SendSelectionCubit>(
      () => _i353.SendSelectionCubit(gh<_i36.PickFilesUseCase>()),
    );
    gh.factory<_i343.StartSendUseCase>(
      () => _i343.StartSendUseCase(
        gh<_i953.TransferEngine>(),
        gh<_i656.SettingsRepository>(),
      ),
    );
    gh.factory<_i312.PairingRepository>(
      () => _i181.PairingRepositoryImpl(
        gh<_i0.SignalingClient>(),
        gh<_i547.PeerConnector>(),
        gh<_i132.AppConfig>(),
        gh<_i639.ActiveHostingRegistry>(),
      ),
    );
    gh.factory<_i259.SendTransferCubit>(
      () => _i259.SendTransferCubit(
        gh<_i343.StartSendUseCase>(),
        gh<_i1032.RecordTransferUseCase>(),
      ),
    );
    gh.factory<_i825.HostSessionUseCase>(
      () => _i825.HostSessionUseCase(gh<_i312.PairingRepository>()),
    );
    gh.factory<_i855.JoinSessionUseCase>(
      () => _i855.JoinSessionUseCase(gh<_i312.PairingRepository>()),
    );
    gh.factory<_i964.PairingCubit>(
      () => _i964.PairingCubit(gh<_i312.PairingRepository>()),
    );
    return this;
  }
}

class _$DatabaseModule extends _i206.DatabaseModule {}

class _$BackgroundModule extends _i762.BackgroundModule {}
