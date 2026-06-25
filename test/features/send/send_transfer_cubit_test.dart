import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';
import '../../helpers/fake_record_transfer.dart';

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

TransferSnapshot _snap(
  TransferPhase phase, {
  int sent = 0,
  int total = 0,
  AppFailure? failure,
  List<FileTransferItem> items = const [],
}) => TransferSnapshot(
  phase: phase,
  role: TransferRole.sender,
  progress: TransferProgress(
    overallBytesTransferred: sent,
    overallTotalBytes: total,
    currentFileIndex: items.isEmpty ? null : 0,
  ),
  items: items,
  failure: failure,
);

void main() {
  late _MockStartSend startSend;
  late StreamController<TransferSnapshot> snapshots;

  setUpAll(() {
    registerFallbackValue(<FileSource>[]);
    registerFallbackValue(_FakeTransport());
  });

  setUp(() {
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
  });

  tearDown(() => snapshots.close());

  blocTest<SendTransferCubit, AppState<TransferView>>(
    'projects transferring then done snapshots into views',
    build: () => SendTransferCubit(startSend, FakeRecordTransfer()),
    act: (cubit) async {
      await cubit.start([], _FakeTransport());
      snapshots
        ..add(_snap(TransferPhase.transferring, sent: 50, total: 100))
        ..add(_snap(TransferPhase.done, sent: 100, total: 100));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<TransferView>>(),
      isA<AppLoaded<TransferView>>()
          .having((s) => s.data.phase, 'phase', TransferPhase.transferring)
          .having((s) => s.data.overallProgress, 'progress', 0.5),
      isA<AppLoaded<TransferView>>()
          .having((s) => s.data.isDone, 'done', true)
          .having((s) => s.data.overallProgress, 'progress', 1.0),
    ],
  );

  blocTest<SendTransferCubit, AppState<TransferView>>(
    'a failed snapshot surfaces as AppError',
    build: () => SendTransferCubit(startSend, FakeRecordTransfer()),
    act: (cubit) async {
      await cubit.start([], _FakeTransport());
      snapshots.add(
        _snap(TransferPhase.failed, failure: const AppFailure.connectionLost()),
      );
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<TransferView>>(),
      isA<AppError<TransferView>>().having(
        (s) => s.failure,
        'failure',
        isA<AppFailureConnectionLost>(),
      ),
    ],
  );

  blocTest<SendTransferCubit, AppState<TransferView>>(
    'cancel delegates to the use case',
    build: () => SendTransferCubit(startSend, FakeRecordTransfer()),
    act: (cubit) async {
      await cubit.start([], _FakeTransport());
      await cubit.cancel();
    },
    verify: (_) => verify(() => startSend.cancel()).called(1),
  );
}
