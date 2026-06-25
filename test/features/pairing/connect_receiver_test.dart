import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';
import 'package:safe_send/features/pairing/presentation/connect/connect_page.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_input.dart';
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

  Future<void> pumpReceiver(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectPage(
          request: ConnectRequest(role: TransferRole.receiver),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the code-entry field and does not join with < 6 digits', (
    tester,
  ) async {
    await pumpReceiver(tester);
    expect(find.byType(CodeInput), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(repo.joinedCodes, isEmpty);
  });

  testWidgets('a complete code joins with the entered value', (tester) async {
    await pumpReceiver(tester);
    await tester.enterText(find.byType(TextField), '012345');
    await tester.pump();

    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    expect(repo.joinedCodes, ['012345']);
  });

  testWidgets('a failure shows a distinct message and preserves the code '
      'so retry re-joins the same value', (tester) async {
    await pumpReceiver(tester);
    await tester.enterText(find.byType(TextField), '012345');
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();

    repo.emit(const PairingState.failed(AppFailure.roomFull()));
    await tester.pump();
    expect(find.text('That room is already full'), findsOneWidget);

    // The code survived the failure: tapping Connect again re-joins it.
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(repo.joinedCodes, ['012345', '012345']);
  });
}
