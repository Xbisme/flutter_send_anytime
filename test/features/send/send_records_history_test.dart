import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';

class _MockStartSend extends Mock implements StartSendUseCase {}

class _MockRecord extends Mock implements RecordTransferUseCase {}

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

class _Source implements FileSource {
  _Source(this.name, this.size);
  @override
  final String name;
  @override
  final int size;
  @override
  String? get mimeType => null;
  @override
  Stream<List<int>> openRead() => const Stream.empty();
}

FileTransferItem _item(int i, FileItemStatus status) =>
    FileTransferItem(index: i, name: 'f$i', size: 10, status: status);

TransferSnapshot _snap(
  TransferPhase phase, {
  List<FileTransferItem> items = const [],
  AppFailure? failure,
}) => TransferSnapshot(
  phase: phase,
  role: TransferRole.sender,
  progress: const TransferProgress(),
  items: items,
  failure: failure,
);

void main() {
  late _MockStartSend startSend;
  late _MockRecord record;
  late StreamController<TransferSnapshot> snapshots;

  setUpAll(() {
    registerFallbackValue(<FileSource>[]);
    registerFallbackValue(_FakeTransport());
    registerFallbackValue(
      TransferRecord(
        id: 'x',
        direction: TransferDirection.sent,
        status: TransferRecordStatus.completed,
        pairingMethod: PairingMethod.sixDigitCode,
        fileCount: 0,
        totalBytes: 0,
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    startSend = _MockStartSend();
    record = _MockRecord();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    when(() => startSend.snapshots).thenAnswer((_) => snapshots.stream);
    when(
      () => startSend(
        sources: any(named: 'sources'),
        transport: any(named: 'transport'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => startSend.dispose()).thenAnswer((_) async {});
    when(
      () => record(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  tearDown(() => snapshots.close());

  Future<void> run(
    SendTransferCubit cubit,
    List<TransferSnapshot> stream,
  ) async {
    await cubit.start([_Source('f0', 10), _Source('f1', 10)], _FakeTransport());
    stream.forEach(snapshots.add);
    await pumpEventQueue();
  }

  test('records one completed sent record on a done transfer', () async {
    final cubit = SendTransferCubit(startSend, record);
    await run(cubit, [
      _snap(
        TransferPhase.transferring,
        items: [_item(0, FileItemStatus.transferring)],
      ),
      _snap(
        TransferPhase.done,
        items: [
          _item(0, FileItemStatus.completed),
          _item(1, FileItemStatus.completed),
        ],
      ),
    ]);

    final captured = verify(() => record(captureAny())).captured;
    expect(captured, hasLength(1));
    final r = captured.single as TransferRecord;
    expect(r.direction, TransferDirection.sent);
    expect(r.status, TransferRecordStatus.completed);
    expect(r.fileCount, 2);
    expect(r.files.every((f) => f.included), isTrue);
    await cubit.close();
  });

  test('records a cancelled record after transfer started', () async {
    final cubit = SendTransferCubit(startSend, record);
    await run(cubit, [
      _snap(
        TransferPhase.transferring,
        items: [_item(0, FileItemStatus.transferring)],
      ),
      _snap(TransferPhase.cancelled, items: [_item(0, FileItemStatus.failed)]),
    ]);
    final r =
        verify(() => record(captureAny())).captured.single as TransferRecord;
    expect(r.status, TransferRecordStatus.cancelled);
    await cubit.close();
  });

  test(
    'records NOTHING when the transfer fails before it starts (FR-001)',
    () async {
      final cubit = SendTransferCubit(startSend, record);
      await run(cubit, [
        _snap(TransferPhase.connecting),
        _snap(
          TransferPhase.failed,
          failure: const AppFailure.transferRejected(),
        ),
      ]);
      verifyNever(() => record(any()));
      await cubit.close();
    },
  );

  test(
    'records exactly once even across multiple terminal snapshots',
    () async {
      final cubit = SendTransferCubit(startSend, record);
      await run(cubit, [
        _snap(
          TransferPhase.transferring,
          items: [_item(0, FileItemStatus.transferring)],
        ),
        _snap(TransferPhase.done, items: [_item(0, FileItemStatus.completed)]),
        _snap(TransferPhase.done, items: [_item(0, FileItemStatus.completed)]),
      ]);
      verify(() => record(any())).called(1);
      await cubit.close();
    },
  );
}
