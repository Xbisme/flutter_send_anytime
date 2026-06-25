import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/transfer/progress_bar.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart';
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart';
import 'package:safe_send/features/receive/presentation/pages/receive_transfer_page.dart';

import '../../helpers/fake_record_transfer.dart';
import '../../helpers/pump_app.dart';

class _MockStartReceive extends Mock implements StartReceiveUseCase {}

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

TransferSnapshot _snap(
  TransferPhase phase, {
  int done = 0,
  int total = 0,
  FileItemStatus status = FileItemStatus.transferring,
}) => TransferSnapshot(
  phase: phase,
  role: TransferRole.receiver,
  progress: TransferProgress(
    overallBytesTransferred: done,
    overallTotalBytes: total,
    currentFileIndex: 0,
  ),
  items: [
    FileTransferItem(
      index: 0,
      name: 'report.pdf',
      size: 100,
      status: status,
      finalPath: '/tmp/report.pdf',
    ),
  ],
);

void main() {
  late _MockStartReceive useCase;
  late StreamController<TransferSnapshot> snapshots;

  setUpAll(() => registerFallbackValue(_FakeTransport()));

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    useCase = _MockStartReceive();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    when(() => useCase.snapshots).thenAnswer((_) => snapshots.stream);
    when(() => useCase.dispose()).thenAnswer((_) async {});
    when(
      () => useCase(
        transport: any(named: 'transport'),
        onManifest: any(named: 'onManifest'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    getIt
      ..unregister<ReceiveTransferCubit>()
      ..registerFactory<ReceiveTransferCubit>(
        () => ReceiveTransferCubit(useCase, FakeRecordTransfer()),
      );
  });
  tearDown(() async {
    await snapshots.close();
    await getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) => tester.pumpApp(
    ReceiveTransferPage(transport: _FakeTransport()),
    locale: const Locale('en'),
  );

  testWidgets('progress shows percent, bar, the RECEIVING badge, and the '
      'current file', (tester) async {
    await pumpPage(tester);
    await tester.pump();
    await tester.pump();
    snapshots.add(_snap(TransferPhase.transferring, done: 50, total: 100));
    await tester.pump();
    await tester.pump();

    expect(find.text('RECEIVING'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.byType(ProgressBar), findsOneWidget);
    expect(find.text('report.pdf'), findsOneWidget);
  });

  testWidgets('done renders the completion summary with Open and Share', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump();
    await tester.pump();
    snapshots.add(
      _snap(
        TransferPhase.done,
        done: 100,
        total: 100,
        status: FileItemStatus.completed,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Received!'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
