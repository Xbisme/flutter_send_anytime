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
import 'package:safe_send/core/services/transport/data_transport.dart' as _i547;
import 'package:safe_send/core/services/transport/transfer_engine.dart'
    as _i953;
import 'package:safe_send/core/services/transport/webrtc_peer_connector.dart'
    as _i603;
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart'
    as _i265;
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart'
    as _i511;

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
    gh.lazySingleton<_i547.PeerConnector>(() => _i603.WebRtcPeerConnector());
    gh.factory<_i511.HomeCubit>(
      () => _i511.HomeCubit(gh<_i265.HomePlaceholderDataSource>()),
    );
    gh.factory<_i953.TransferEngine>(
      () => _i953.TransferEngine(
        gh<_i547.PeerConnector>(),
        gh<_i132.AppConfig>(),
      ),
    );
    return this;
  }
}
