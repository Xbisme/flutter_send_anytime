import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';
import 'package:safe_send/features/send/presentation/pages/send_transfer_page.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';

import '../../helpers/pump_app.dart';

class _MockStartSend extends Mock implements StartSendUseCase {}

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

void main() {
  late _MockStartSend startSend;
  late StreamController<TransferSnapshot> snapshots;

  setUpAll(() {
    registerFallbackValue(<FileSource>[]);
    registerFallbackValue(_FakeTransport());
  });

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    startSend = _MockStartSend();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    when(() => startSend.snapshots).thenAnswer((_) => snapshots.stream);
    when(
      () => startSend(
        sources: any(named: 'sources'),
        transport: any(named: 'transport'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => startSend.cancel()).thenAnswer((_) async {});
    when(() => startSend.dispose()).thenAnswer((_) async {});
    getIt
      ..unregister<SendTransferCubit>()
      ..registerFactory<SendTransferCubit>(() => SendTransferCubit(startSend));
  });
  tearDown(() async {
    await snapshots.close();
    await getIt.reset();
  });

  Future<void> pumpFailure(WidgetTester tester, AppFailure failure) async {
    await tester.pumpApp(
      SendTransferPage(
        args: SendProgressArgs(sources: const [], transport: _FakeTransport()),
      ),
      locale: const Locale('en'),
    );
    await tester.pump();
    snapshots.add(
      TransferSnapshot(
        phase: TransferPhase.failed,
        role: TransferRole.sender,
        progress: const TransferProgress(),
        failure: failure,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a declined transfer shows a distinct message + retry', (
    tester,
  ) async {
    await pumpFailure(tester, const AppFailure.transferRejected());

    expect(find.text('Send failed'), findsOneWidget);
    expect(find.text('The receiver declined'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a lost connection shows the connection-lost message', (
    tester,
  ) async {
    await pumpFailure(tester, const AppFailure.connectionLost());

    expect(find.text('Lost connection to the other device'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a file read failure shows the read-failure message', (
    tester,
  ) async {
    await pumpFailure(tester, const AppFailure.fileReadFailed());

    expect(find.text("Couldn't read the selected file"), findsOneWidget);
  });
}
