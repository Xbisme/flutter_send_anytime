import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/services/nearby/nearby_discovery_service.dart';
import 'package:safe_send/core/services/nearby/nearby_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/nearby_browse_panel.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/nearby_device_row.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

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

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    discovery = FakeNearbyDiscoveryService();
    permission = _MockPermission();
    getIt
      ..unregister<NearbyDiscoveryService>()
      ..registerSingleton<NearbyDiscoveryService>(discovery)
      ..unregister<NearbyPermissionService>()
      ..registerSingleton<NearbyPermissionService>(permission);
  });

  tearDown(() async {
    await discovery.dispose();
    await getIt.reset();
  });

  Future<void> pump(
    WidgetTester tester, {
    required void Function(NearbyDevice) onJoin,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: NearbyBrowsePanel(onJoin: onJoin)),
      ),
    );
    await tester.pump();
  }

  testWidgets('granted: lists discovered devices and a tap joins (US1)', (
    tester,
  ) async {
    when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.granted);
    NearbyDevice? tapped;
    await pump(tester, onJoin: (d) => tapped = d);
    await tester.pump(); // resolve permission future

    discovery.emit([device]);
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    await tester.tap(find.byType(NearbyDeviceRow));
    expect(tapped, device);
  });

  testWidgets('granted + nobody nearby: shows the same-Wi-Fi empty state', (
    tester,
  ) async {
    when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.granted);
    await pump(tester, onJoin: (_) {});
    await tester.pump();

    expect(find.text('No devices yet'), findsOneWidget);
  });

  testWidgets('permanentlyDenied: shows blocked state with Open Settings', (
    tester,
  ) async {
    when(
      () => permission.ensure(),
    ).thenAnswer((_) async => NearbyPermissionStatus.permanentlyDenied);
    await pump(tester, onJoin: (_) {});
    await tester.pump();

    expect(find.text('Open Settings'), findsOneWidget);
  });
}
