import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart';
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart';
import '../../helpers/fake_record_transfer.dart';

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

const _manifest = TransferManifest(
  v: TransferConstants.kProtocolVersion,
  sessionId: 's',
  fileCount: 2,
  totalBytes: 300,
  files: [
    ManifestFileEntry(index: 0, name: 'a.jpg', size: 100),
    ManifestFileEntry(index: 1, name: 'b.pdf', size: 200),
  ],
);

void main() {
  late _MockStartReceive useCase;
  late StreamController<TransferSnapshot> snapshots;
  late bool? decisionValue;

  setUpAll(() {
    registerFallbackValue(_FakeTransport());
    registerFallbackValue((TransferManifest _) async => true);
  });

  setUp(() {
    useCase = _MockStartReceive();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    decisionValue = null;
    when(() => useCase.snapshots).thenAnswer((_) => snapshots.stream);
    when(() => useCase.dispose()).thenAnswer((_) async {});
    // call() invokes the onManifest bridge and records the decision.
    when(
      () => useCase(
        transport: any(named: 'transport'),
        onManifest: any(named: 'onManifest'),
      ),
    ).thenAnswer((invocation) async {
      final onManifest =
          invocation.namedArguments[#onManifest]
              as Future<bool> Function(TransferManifest);
      decisionValue = await onManifest(_manifest);
      return const Result.success(null);
    });
  });
  tearDown(() async => snapshots.close());

  blocTest<ReceiveTransferCubit, AppState<TransferView>>(
    'manifest surfaces an awaiting-decision view with the offer; '
    'accept resolves the gate with true',
    build: () => ReceiveTransferCubit(useCase, FakeRecordTransfer()),
    act: (cubit) async {
      final running = cubit.start(_FakeTransport(), senderLabel: 'Người gửi');
      await pumpEventQueue();
      cubit.accept();
      await running;
    },
    expect: () => [
      isA<AppLoading<TransferView>>(),
      isA<AppLoaded<TransferView>>()
          .having((s) => s.data.awaitingDecision, 'awaiting', true)
          .having((s) => s.data.incomingOffer?.fileCount, 'fileCount', 2)
          .having((s) => s.data.incomingOffer?.totalBytes, 'totalBytes', 300)
          .having(
            (s) => s.data.incomingOffer?.senderLabel,
            'peer',
            'Người gửi',
          ),
    ],
    verify: (cubit) {
      expect(decisionValue, isTrue);
      expect(cubit.rejectedByUser, isFalse);
    },
  );

  blocTest<ReceiveTransferCubit, AppState<TransferView>>(
    'reject resolves the gate with false and flags a user reject',
    build: () => ReceiveTransferCubit(useCase, FakeRecordTransfer()),
    act: (cubit) async {
      final running = cubit.start(_FakeTransport(), senderLabel: 'Người gửi');
      await pumpEventQueue();
      cubit.reject();
      await running;
    },
    verify: (cubit) {
      expect(decisionValue, isFalse);
      expect(cubit.rejectedByUser, isTrue);
    },
  );

  blocTest<ReceiveTransferCubit, AppState<TransferView>>(
    'a failed snapshot with some completed files emits a partial loaded view, '
    'not an error (FR-013a)',
    build: () => ReceiveTransferCubit(useCase, FakeRecordTransfer()),
    act: (cubit) async {
      final running = cubit.start(_FakeTransport(), senderLabel: 'Người gửi');
      await pumpEventQueue();
      cubit.accept();
      // File 0 verified, then the connection drops mid file 1.
      snapshots.add(
        const TransferSnapshot(
          phase: TransferPhase.failed,
          role: TransferRole.receiver,
          progress: TransferProgress(
            overallBytesTransferred: 100,
            overallTotalBytes: 300,
          ),
          items: [
            FileTransferItem(
              index: 0,
              name: 'a.jpg',
              size: 100,
              status: FileItemStatus.completed,
            ),
            FileTransferItem(index: 1, name: 'b.pdf', size: 200),
          ],
          failure: AppFailure.connectionLost(),
        ),
      );
      await pumpEventQueue();
      await running;
    },
    verify: (cubit) {
      final state = cubit.state;
      expect(state, isA<AppLoaded<TransferView>>());
      final view = (state as AppLoaded<TransferView>).data;
      expect(view.isPartial, isTrue);
      expect(view.completedCount, 1);
    },
  );
}
