import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/services/permissions/camera_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_state.dart';

class _MockPermission extends Mock implements CameraPermissionService {}

void main() {
  late _MockPermission permission;
  final validUri = ConnectLink.build('042815');

  setUp(() {
    permission = _MockPermission();
  });

  QrScanCubit build() => QrScanCubit(permission);

  QrScanView? loaded(QrScanCubit c) {
    final s = c.state;
    return s is AppLoaded<QrScanView> ? s.data : null;
  }

  group('init / permission (FR-015/016)', () {
    blocTest<QrScanCubit, AppState<QrScanView>>(
      'granted → camera-ready loaded state',
      setUp: () => when(permission.status).thenAnswer(
        (_) async => CameraPermissionStatus.granted,
      ),
      build: build,
      act: (c) => c.init(),
      verify: (c) => expect(
        loaded(c)?.permission,
        CameraPermissionStatus.granted,
      ),
    );

    for (final status in [
      CameraPermissionStatus.denied,
      CameraPermissionStatus.permanentlyDenied,
      CameraPermissionStatus.restricted,
    ]) {
      blocTest<QrScanCubit, AppState<QrScanView>>(
        'maps $status through init',
        setUp: () => when(permission.status).thenAnswer((_) async => status),
        build: build,
        act: (c) => c.init(),
        verify: (c) => expect(loaded(c)?.permission, status),
      );
    }

    blocTest<QrScanCubit, AppState<QrScanView>>(
      'requestPermission updates the status',
      setUp: () {
        when(permission.status).thenAnswer(
          (_) async => CameraPermissionStatus.denied,
        );
        when(permission.request).thenAnswer(
          (_) async => CameraPermissionStatus.granted,
        );
      },
      build: build,
      act: (c) async {
        await c.init();
        await c.requestPermission();
      },
      verify: (c) => expect(
        loaded(c)?.permission,
        CameraPermissionStatus.granted,
      ),
    );
  });

  group('onDetected', () {
    setUp(
      () => when(permission.status).thenAnswer(
        (_) async => CameraPermissionStatus.granted,
      ),
    );

    test('valid code → accepted once, then latched (FR-014)', () async {
      final c = build();
      await c.init();
      expect(c.onDetected(validUri), ScanOutcome.accepted);
      expect(c.acceptedCode, '042815');
      expect(loaded(c)?.handled, isTrue);
      // A second detection is ignored — single join.
      expect(c.onDetected(validUri), ScanOutcome.ignored);
      await c.close();
    });

    test(
      'foreign QR → invalid, stays loaded (no terminal error) (FR-012)',
      () async {
        final c = build();
        await c.init();
        expect(c.onDetected('https://example.com'), ScanOutcome.invalid);
        expect(c.state, isA<AppLoaded<QrScanView>>());
        expect(loaded(c)?.handled, isFalse);
        // Same foreign value repeated is debounced.
        expect(c.onDetected('https://example.com'), ScanOutcome.ignored);
        await c.close();
      },
    );

    test('image-derived valid raw → accepted (US3 pick-from-photo)', () async {
      final c = build();
      await c.init();
      expect(c.onDetected(ConnectLink.build('999000')), ScanOutcome.accepted);
      expect(c.acceptedCode, '999000');
      await c.close();
    });

    test('null/empty raw → ignored', () async {
      final c = build();
      await c.init();
      expect(c.onDetected(null), ScanOutcome.ignored);
      expect(c.onDetected(''), ScanOutcome.ignored);
      await c.close();
    });
  });

  test('toggleTorch flips torchOn (FR-017a)', () async {
    when(permission.status).thenAnswer(
      (_) async => CameraPermissionStatus.granted,
    );
    final c = build();
    await c.init();
    expect(loaded(c)?.torchOn, isFalse);
    c.toggleTorch();
    expect(loaded(c)?.torchOn, isTrue);
    await c.close();
  });
}
