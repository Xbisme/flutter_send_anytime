import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/config/signaling_endpoint_provider.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/services/signaling/signaling_diagnostics_service.dart';

import '../../helpers/settings_fakes.dart';

void main() {
  final defaultEndpoint = Uri.parse('wss://default.relay:8443');
  final override = Uri.parse('wss://my.relay:9000');

  AppConfig config() =>
      AppConfig(flavor: AppFlavor.dev, signalingEndpoint: defaultEndpoint);

  group('SignalingEndpointProvider (US4)', () {
    test('falls back to the flavor default when no override', () {
      final provider = DefaultSignalingEndpointProvider(
        config(),
        FakeSettingsRepository(),
      );
      expect(provider.effective(), defaultEndpoint);
    });

    test('uses the override when set', () {
      final provider = DefaultSignalingEndpointProvider(
        config(),
        FakeSettingsRepository(
          AppSettings(deviceName: 'D', signalingOverride: override),
        ),
      );
      expect(provider.effective(), override);
    });
  });

  group('SignalingDiagnosticsService (US4, FR-015)', () {
    test('success when the probe completes', () async {
      final svc = WebSocketSignalingDiagnostics.withProbe((_, _) async {});
      expect(await svc.probe(defaultEndpoint), isA<Success<void>>());
    });

    test('failure when the probe throws', () async {
      final svc = WebSocketSignalingDiagnostics.withProbe(
        (_, _) async => throw Exception('unreachable'),
      );
      expect(await svc.probe(defaultEndpoint), isA<Failure<void>>());
    });
  });

  group('SettingsCubit.runDiagnostic', () {
    test(
      'reports reachable / unreachable via the effective endpoint',
      () async {
        final reachable = makeSettingsCubit(
          endpoint: FakeSignalingEndpointProvider(defaultEndpoint),
          diagnostics: FakeSignalingDiagnostics()..reachable = true,
        );
        expect(await reachable.runDiagnostic(), isA<Success<void>>());
        await reachable.close();

        final down = makeSettingsCubit(
          endpoint: FakeSignalingEndpointProvider(defaultEndpoint),
          diagnostics: FakeSignalingDiagnostics()..reachable = false,
        );
        expect(await down.runDiagnostic(), isA<Failure<void>>());
        await down.close();
      },
    );

    test('unreachable when no endpoint is configured', () async {
      final cubit = makeSettingsCubit(
        endpoint: FakeSignalingEndpointProvider(),
      );
      expect(await cubit.runDiagnostic(), isA<Failure<void>>());
      await cubit.close();
    });
  });
}
