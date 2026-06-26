import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';
import 'package:safe_send/features/pairing/presentation/connect/connect_page.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

import '../../core/services/nearby/fake_nearby_discovery_service.dart';

class _MockPermission extends Mock implements NearbyPermissionService {}

class _FakeTransport implements DataTransport {
  @override
  Stream<Uint8List> get inbound => const Stream.empty();
  @override
  int get bufferedAmount => 0;
  @override
  Stream<void> get onBufferedAmountLow => const Stream.empty();
  @override
  Future<void> get closed => Completer<void>().future;
  @override
  void setBufferedAmountLowThreshold(int value) {}
  @override
  Future<void> send(Uint8List data) async {}
  @override
  Future<void> close() async {}
}

class _FakePairingRepository implements PairingRepository {
  final _controller = StreamController<PairingState>.broadcast();
  int hostCalls = 0;

  @override
  Stream<PairingState> get state => _controller.stream;
  @override
  Future<Result<PairingCode>> host() async {
    hostCalls++;
    return Result.success(
      PairingCode.fromTtl(value: '042815', ttl: const Duration(minutes: 5)),
    );
  }

  @override
  Future<Result<void>> join(String code) async => const Result.success(null);
  @override
  DataTransport? takeTransport() => _FakeTransport();
  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
  }

  void emit(PairingState s) => _controller.add(s);
}

void main() {
  late _FakePairingRepository repo;
  late FakeNearbyDiscoveryService discovery;
  late _MockPermission permission;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    repo = _FakePairingRepository();
    discovery = FakeNearbyDiscoveryService();
    permission = _MockPermission();
    when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.granted);
    getIt
      ..unregister<PairingCubit>()
      ..registerFactory<PairingCubit>(() => PairingCubit(repo))
      ..unregister<NearbyDiscoveryService>()
      ..registerSingleton<NearbyDiscoveryService>(discovery)
      ..unregister<NearbyPermissionService>()
      ..registerSingleton<NearbyPermissionService>(permission);
  });

  tearDown(() async {
    await discovery.dispose();
    await getIt.reset();
  });

  Future<void> pumpSender(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectPage(request: ConnectRequest(role: TransferRole.sender)),
      ),
    );
    await tester.pump();
  }

  testWidgets('sender Gần đây tab advertises the live code + shows the privacy '
      'note, without re-hosting (US2/FR-009)', (tester) async {
    await pumpSender(tester);
    repo.emit(
      PairingState.hosting(
        PairingCode.fromTtl(value: '042815', ttl: const Duration(minutes: 5)),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Nearby'));
    await tester.pump(); // build the panel
    await tester.pump(); // run the post-frame advertise seed

    expect(discovery.advertisedCode, '042815');
    expect(
      find.text('Your device name is broadcast to nearby devices.'),
      findsOneWidget,
    );

    // Switching tabs must not issue a second code.
    await tester.tap(find.text('6-digit'));
    await tester.pump();
    expect(repo.hostCalls, 1);
  });
}
