import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/inputs/code_box.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';
import 'package:safe_send/features/pairing/domain/usecases/host_session_usecase.dart';
import 'package:safe_send/features/pairing/domain/usecases/join_session_usecase.dart';
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
  final _FakeTransport transport = _FakeTransport();
  bool tookTransport = false;

  @override
  Stream<PairingState> get state => _controller.stream;
  @override
  Future<Result<PairingCode>> host() async => Result.success(
    PairingCode.fromTtl(value: '012345', ttl: const Duration(minutes: 5)),
  );
  @override
  Future<Result<void>> join(String code) async => const Result.success(null);
  @override
  DataTransport? takeTransport() {
    tookTransport = true;
    return transport;
  }

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
  }

  void emit(PairingState s) => _controller.add(s);
}

void main() {
  late _FakePairingRepository repo;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    repo = _FakePairingRepository();
    getIt
      ..unregister<PairingCubit>()
      ..registerFactory<PairingCubit>(
        () => PairingCubit(
          HostSessionUseCase(repo),
          JoinSessionUseCase(repo),
          repo,
        ),
      );
  });
  tearDown(() async => getIt.reset());

  ConnectResult? popped;

  Widget harness() {
    popped = null;
    var pushed = false;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) {
            if (!pushed) {
              pushed = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                popped = await context.push<ConnectResult>('/connect');
              });
            }
            return const Scaffold();
          },
        ),
        GoRoute(
          path: '/connect',
          builder: (_, _) => const ConnectPage(
            request: ConnectRequest(role: TransferRole.sender),
          ),
        ),
      ],
    );
    return MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  // Pumps the harness, lets the post-frame push reach /connect.
  Future<void> openConnect(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pump(); // run the post-frame push
    await tester.pump(); // build /connect
  }

  testWidgets('hosting renders the 6-digit code + expiry countdown', (
    tester,
  ) async {
    await openConnect(tester);
    repo.emit(
      PairingState.hosting(
        PairingCode.fromTtl(value: '012345', ttl: const Duration(minutes: 5)),
      ),
    );
    await tester.pump();

    expect(find.byType(CodeBox), findsNWidgets(6));
    expect(find.textContaining('Expires in'), findsOneWidget);
    expect(find.text('6-digit'), findsOneWidget);
    expect(find.text('Nearby'), findsOneWidget);
  });

  testWidgets('a failure shows a message and a refresh action', (tester) async {
    await openConnect(tester);
    repo.emit(const PairingState.failed(AppFailure.roomFull()));
    await tester.pump();

    expect(find.text('That room is already full'), findsOneWidget);
    expect(find.text('Get a new code'), findsOneWidget);
  });

  testWidgets('connected hands the transport back as a ConnectResult', (
    tester,
  ) async {
    await openConnect(tester);
    expect(find.byType(ConnectPage), findsOneWidget);

    repo.emit(const PairingState.connected());
    await tester.pump(); // listener fires → takeTransport + pop
    await tester.pump(); // settle the pop transition

    expect(repo.tookTransport, isTrue);
    expect(popped, isNotNull);
    expect(find.byType(ConnectPage), findsNothing);
  });
}
