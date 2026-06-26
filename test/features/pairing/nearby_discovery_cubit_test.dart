import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/connect/nearby_discovery_cubit.dart';

import '../../core/services/nearby/fake_nearby_discovery_service.dart';

class _MockPermission extends Mock implements NearbyPermissionService {}

void main() {
  late FakeNearbyDiscoveryService discovery;
  late _MockPermission permission;

  final device = NearbyDevice(
    id: 'a',
    displayName: 'Alice',
    code: '042815',
    lastSeen: DateTime(2026),
  );

  setUp(() {
    discovery = FakeNearbyDiscoveryService();
    permission = _MockPermission();
  });

  tearDown(() => discovery.dispose());

  NearbyDiscoveryCubit build() => NearbyDiscoveryCubit(discovery, permission);

  NearbyBrowse? loaded(NearbyDiscoveryCubit c) {
    final s = c.state;
    return s is AppLoaded<NearbyBrowse> ? s.data : null;
  }

  blocTest<NearbyDiscoveryCubit, AppState<NearbyBrowse>>(
    'granted → discovering, then lists discovered devices (US1)',
    setUp: () => when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.granted),
    build: build,
    act: (c) async {
      await c.start();
      discovery.emit([device]);
      await Future<void>.delayed(Duration.zero);
    },
    verify: (c) {
      final data = loaded(c);
      expect(data, isA<NearbyBrowsing>());
      expect((data! as NearbyBrowsing).devices, [device]);
    },
  );

  blocTest<NearbyDiscoveryCubit, AppState<NearbyBrowse>>(
    'denied → blocked (not permanent) and never browses (FR-012/SC-005)',
    setUp: () => when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.denied),
    build: build,
    act: (c) => c.start(),
    verify: (c) {
      final data = loaded(c);
      expect(data, isA<NearbyBrowseBlocked>());
      expect((data! as NearbyBrowseBlocked).permanent, isFalse);
      expect(discovery.discovering, isFalse);
    },
  );

  blocTest<NearbyDiscoveryCubit, AppState<NearbyBrowse>>(
    'permanentlyDenied → blocked permanent (Open Settings path)',
    setUp: () => when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.permanentlyDenied),
    build: build,
    act: (c) => c.start(),
    verify: (c) =>
        expect((loaded(c)! as NearbyBrowseBlocked).permanent, isTrue),
  );
}
