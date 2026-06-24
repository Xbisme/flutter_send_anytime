import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/transfer/progress_bar.dart';
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

TransferSnapshot _snap(TransferPhase phase, {int sent = 0, int total = 0}) =>
    TransferSnapshot(
      phase: phase,
      role: TransferRole.sender,
      progress: TransferProgress(
        overallBytesTransferred: sent,
        overallTotalBytes: total,
        currentFileIndex: 0,
      ),
      items: const [FileTransferItem(index: 0, name: 'photo.jpg', size: 100)],
    );

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

  Future<void> pumpPage(WidgetTester tester) => tester.pumpApp(
    SendTransferPage(
      args: SendProgressArgs(sources: const [], transport: _FakeTransport()),
    ),
    locale: const Locale('en'),
  );

  testWidgets('progress view shows percent, bar and the SENDING badge', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump();
    await tester.pump();
    snapshots.add(_snap(TransferPhase.transferring, sent: 50, total: 100));
    await tester.pump();
    await tester.pump();

    expect(find.text('SENDING'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
    expect(find.text('photo.jpg'), findsOneWidget);
  });

  testWidgets('done renders the completion summary with both actions', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump();
    await tester.pump();
    snapshots.add(_snap(TransferPhase.done, sent: 100, total: 100));
    await tester.pump();
    await tester.pump();

    expect(find.text('Done!'), findsOneWidget);
    expect(find.textContaining('Sent'), findsOneWidget);
    expect(find.text('Send more'), findsOneWidget);
  });
}
