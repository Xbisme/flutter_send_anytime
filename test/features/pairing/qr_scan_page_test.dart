import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/services/permissions/camera_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart';
import 'package:safe_send/features/pairing/presentation/scan/qr_scan_page.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

class _MockPermission extends Mock implements CameraPermissionService {}

void main() {
  late _MockPermission permission;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    permission = _MockPermission();
    getIt
      ..unregister<QrScanCubit>()
      ..registerFactory<QrScanCubit>(() => QrScanCubit(permission));
  });
  tearDown(() async => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: QrScanPage(),
      ),
    );
    await tester.pump(); // resolve init() permission future
    await tester.pump();
  }

  testWidgets('permanently-denied shows Open Settings + pick-from-photo, '
      'no dead preview (FR-016)', (tester) async {
    when(permission.status).thenAnswer(
      (_) async => CameraPermissionStatus.permanentlyDenied,
    );

    await pump(tester);

    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.text('Choose a photo with a QR code'), findsOneWidget);

    when(permission.openSettings).thenAnswer((_) async {});
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    verify(permission.openSettings).called(1);
  });
}
