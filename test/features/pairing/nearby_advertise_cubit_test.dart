import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/connect/nearby_advertise_cubit.dart';

import '../../core/services/nearby/fake_nearby_discovery_service.dart';

class _MockPermission extends Mock implements NearbyPermissionService {}

void main() {
  late FakeNearbyDiscoveryService discovery;
  late _MockPermission permission;

  setUp(() {
    discovery = FakeNearbyDiscoveryService();
    permission = _MockPermission();
  });

  tearDown(() => discovery.dispose());

  NearbyAdvertiseCubit build() => NearbyAdvertiseCubit(discovery, permission);

  NearbyAdvertise? loaded(NearbyAdvertiseCubit c) {
    final s = c.state;
    return s is AppLoaded<NearbyAdvertise> ? s.data : null;
  }

  blocTest<NearbyAdvertiseCubit, AppState<NearbyAdvertise>>(
    'granted → advertises the live code (US2/FR-009)',
    setUp: () => when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.granted),
    build: build,
    act: (c) => c.start(code: '042815', displayName: 'Safe Send · ABCD'),
    verify: (c) {
      // bloc_test closes the cubit (→ stopAdvertise) before verify, so assert
      // the emitted state rather than the fake's post-stop fields.
      final data = loaded(c);
      expect(data, isA<NearbyAdvertiseActive>());
      expect((data! as NearbyAdvertiseActive).code, '042815');
    },
  );

  blocTest<NearbyAdvertiseCubit, AppState<NearbyAdvertise>>(
    'denied → blocked, never advertises (FR-012/SC-005)',
    setUp: () => when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.denied),
    build: build,
    act: (c) => c.start(code: '042815', displayName: 'x'),
    verify: (c) {
      expect(loaded(c), isA<NearbyAdvertiseBlocked>());
      expect(discovery.advertisedCode, isNull);
    },
  );

  blocTest<NearbyAdvertiseCubit, AppState<NearbyAdvertise>>(
    'advertise failure → error',
    setUp: () {
      when(
        () => permission.ensure(),
      ).thenAnswer((_) async => NearbyPermissionStatus.granted);
      discovery.advertiseResult = const Result.failure(
        AppFailure.networkError(),
      );
    },
    build: build,
    act: (c) => c.start(code: '042815', displayName: 'x'),
    verify: (c) => expect(c.state, isA<AppError<NearbyAdvertise>>()),
  );
}
