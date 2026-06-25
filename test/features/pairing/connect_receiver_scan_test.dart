import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';
import 'package:safe_send/features/pairing/presentation/connect/connect_page.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

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
  final List<String> joinedCodes = [];

  @override
  Stream<PairingState> get state => _controller.stream;
  @override
  Future<Result<PairingCode>> host() async => Result.success(
    PairingCode.fromTtl(value: '000000', ttl: const Duration(minutes: 5)),
  );
  @override
  Future<Result<void>> join(String code) async {
    joinedCodes.add(code);
    return const Result.success(null);
  }

  @override
  DataTransport? takeTransport() => _FakeTransport();
  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
  }
}

/// Stand-in for the real scanner route — pops a decoded code immediately.
class _StubScanner extends StatefulWidget {
  const _StubScanner();
  @override
  State<_StubScanner> createState() => _StubScannerState();
}

class _StubScannerState extends State<_StubScanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.pop('123456'),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  late _FakePairingRepository repo;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    repo = _FakePairingRepository();
    getIt
      ..unregister<PairingCubit>()
      ..registerFactory<PairingCubit>(() => PairingCubit(repo));
  });
  tearDown(() async => getIt.reset());

  testWidgets('tapping "Scan QR code" pushes the scanner and joins with the '
      'returned code (FR-009/010)', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.connect,
      routes: [
        GoRoute(
          path: AppRoutes.connect,
          builder: (_, _) => const ConnectPage(
            request: ConnectRequest(role: TransferRole.receiver),
          ),
        ),
        GoRoute(
          path: AppRoutes.qrScan,
          builder: (_, _) => const _StubScanner(),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    // ConnectPage runs a 1s countdown ticker, so pumpAndSettle never settles —
    // pump explicit frames instead.
    await tester.pump();

    await tester.tap(find.text('Scan QR code'));
    await tester.pump(); // push the scanner route
    await tester.pump(); // stub scanner's post-frame pop(code)
    await tester.pump(); // join with the returned code

    expect(repo.joinedCodes, ['123456']);
  });
}
