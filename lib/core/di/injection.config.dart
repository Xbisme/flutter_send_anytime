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
import 'package:safe_send/core/services/file/file_picker_service.dart'
    as _i1069;
import 'package:safe_send/core/services/file/file_picker_service_impl.dart'
    as _i661;
import 'package:safe_send/core/services/signaling/signaling_client.dart' as _i0;
import 'package:safe_send/core/services/signaling/signaling_socket.dart'
    as _i990;
import 'package:safe_send/core/services/transport/data_transport.dart' as _i547;
import 'package:safe_send/core/services/transport/transfer_engine.dart'
    as _i953;
import 'package:safe_send/core/services/transport/webrtc_peer_connector.dart'
    as _i603;
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart'
    as _i265;
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart'
    as _i511;
import 'package:safe_send/features/pairing/data/pairing_repository_impl.dart'
    as _i181;
import 'package:safe_send/features/pairing/domain/pairing_repository.dart'
    as _i312;
import 'package:safe_send/features/pairing/domain/usecases/host_session_usecase.dart'
    as _i825;
import 'package:safe_send/features/pairing/domain/usecases/join_session_usecase.dart'
    as _i855;
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart'
    as _i964;
import 'package:safe_send/features/send/domain/usecases/pick_files_usecase.dart'
    as _i36;
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart'
    as _i343;
import 'package:safe_send/features/send/presentation/cubit/send_selection_cubit.dart'
    as _i353;
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart'
    as _i259;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.lazySingleton<_i265.HomePlaceholderDataSource>(
      () => _i265.HomePlaceholderDataSource(),
    );
    gh.factory<_i0.SignalingClient>(
      () => _i0.SignalingClient(
        gh<_i132.AppConfig>(),
        opener: gh<_i990.SignalingSocketOpener>(),
      ),
    );
    gh.lazySingleton<_i547.PeerConnector>(() => _i603.WebRtcPeerConnector());
    gh.factory<_i1069.FilePickerService>(
      () => const _i661.FilePickerServiceImpl(),
    );
    gh.factory<_i312.PairingRepository>(
      () => _i181.PairingRepositoryImpl(
        gh<_i0.SignalingClient>(),
        gh<_i547.PeerConnector>(),
        gh<_i132.AppConfig>(),
      ),
    );
    gh.factory<_i511.HomeCubit>(
      () => _i511.HomeCubit(gh<_i265.HomePlaceholderDataSource>()),
    );
    gh.factory<_i825.HostSessionUseCase>(
      () => _i825.HostSessionUseCase(gh<_i312.PairingRepository>()),
    );
    gh.factory<_i855.JoinSessionUseCase>(
      () => _i855.JoinSessionUseCase(gh<_i312.PairingRepository>()),
    );
    gh.factory<_i953.TransferEngine>(
      () => _i953.TransferEngine(
        gh<_i547.PeerConnector>(),
        gh<_i132.AppConfig>(),
      ),
    );
    gh.factory<_i343.StartSendUseCase>(
      () => _i343.StartSendUseCase(gh<_i953.TransferEngine>()),
    );
    gh.factory<_i36.PickFilesUseCase>(
      () => _i36.PickFilesUseCase(gh<_i1069.FilePickerService>()),
    );
    gh.factory<_i964.PairingCubit>(
      () => _i964.PairingCubit(
        gh<_i825.HostSessionUseCase>(),
        gh<_i855.JoinSessionUseCase>(),
        gh<_i312.PairingRepository>(),
      ),
    );
    gh.factory<_i353.SendSelectionCubit>(
      () => _i353.SendSelectionCubit(gh<_i36.PickFilesUseCase>()),
    );
    gh.factory<_i259.SendTransferCubit>(
      () => _i259.SendTransferCubit(gh<_i343.StartSendUseCase>()),
    );
    return this;
  }
}
