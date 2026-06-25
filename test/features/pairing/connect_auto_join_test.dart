import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
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

  void emit(PairingState s) => _controller.add(s);
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

  testWidgets('a share-link autoJoinCode auto-joins and pairs as shareLink '
      '(FR-012 / FR-017)', (tester) async {
    ConnectResult? popped;
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (_, _) => Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    popped = await context.push<ConnectResult>(
                      '/connect',
                      extra: const ConnectRequest(
                        role: TransferRole.receiver,
                        autoJoinCode: '123456',
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/connect',
          builder: (_, state) =>
              ConnectPage(request: state.extra! as ConnectRequest),
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

    await tester.tap(find.text('open'));
    await tester.pump(); // build ConnectPage + register the post-frame join
    await tester.pump(); // post-frame callback fires → joinWithCode

    expect(repo.joinedCodes, ['123456']);

    // The channel opens → the page pops a ConnectResult tagged shareLink.
    // (Avoid pumpAndSettle — the Connect page's 1s expiry ticker never settles.)
    repo.emit(const PairingState.connected());
    await tester.pump(); // cubit emits connected → listener → pop initiated
    await tester.pump(const Duration(milliseconds: 400)); // pop transition

    expect(popped, isNotNull);
    expect(popped!.method, PairingMethod.shareLink);
  });
}
