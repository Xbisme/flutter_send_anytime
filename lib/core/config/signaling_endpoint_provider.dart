import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';

/// The effective signaling endpoint (#010, US4): the user's validated override
/// when set, otherwise the per-flavor default from [AppConfig]. Keeps signaling
/// config centralized (Constitution VIII) — call sites never read the override
/// directly.
// ignore: one_member_abstracts
abstract interface class SignalingEndpointProvider {
  /// The endpoint the next pairing should use, or null if none is configured.
  Uri? effective();
}

@LazySingleton(as: SignalingEndpointProvider)
class DefaultSignalingEndpointProvider implements SignalingEndpointProvider {
  DefaultSignalingEndpointProvider(this._config, this._settings);

  final AppConfig _config;
  final SettingsRepository _settings;

  @override
  Uri? effective() =>
      _settings.current.signalingOverride ?? _config.signalingEndpoint;
}
