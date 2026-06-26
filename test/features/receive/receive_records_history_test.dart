import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart';
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart';
import '../../helpers/settings_fakes.dart';

class _MockStartReceive extends Mock implements StartReceiveUseCase {}

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

FileTransferItem _item(int i, String name, int size, FileItemStatus status) =>
    FileTransferItem(
      index: i,
      name: name,
      size: size,
      status: status,
      finalPath: status == FileItemStatus.completed ? '/dest/$name' : null,
    );

TransferSnapshot _snap(
  TransferPhase phase, {
  required List<FileTransferItem> items,
  AppFailure? failure,
}) => TransferSnapshot(
  phase: phase,
  role: TransferRole.receiver,
  progress: const TransferProgress(),
  items: items,
  failure: failure,
);

void main() {
  late _MockStartReceive useCase;
  late _MockRecord record;
  late StreamController<TransferSnapshot> snapshots;

  setUpAll(() {
    registerFallbackValue(_FakeTransport());
    registerFallbackValue((TransferManifest _) async => true);
    registerFallbackValue(
      TransferRecord(
        id: 'x',
        direction: TransferDirection.received,
        status: TransferRecordStatus.completed,
        pairingMethod: PairingMethod.sixDigitCode,
        fileCount: 0,
        totalBytes: 0,
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    useCase = _MockStartReceive();
    record = _MockRecord();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    when(() => useCase.snapshots).thenAnswer((_) => snapshots.stream);
    when(() => useCase.dispose()).thenAnswer((_) async {});
    when(
      () => record(any()),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => useCase(
        transport: any(named: 'transport'),
        onManifest: any(named: 'onManifest'),
      ),
    ).thenAnswer((invocation) async {
      final onManifest =
          invocation.namedArguments[#onManifest]
              as Future<bool> Function(TransferManifest);
      await onManifest(_manifest);
      return const Result.success(null);
    });
  });
  tearDown(() => snapshots.close());

  test('records a completed received record after accept + done', () async {
    final cubit = ReceiveTransferCubit(
      useCase,
      record,
      FakeSettingsRepository(),
      FakeGallerySaver(),
      FakeIncomingFileNotifier(),
    );
    unawaited(cubit.start(_FakeTransport(), senderLabel: 'Người gửi'));
    await pumpEventQueue();
    cubit.accept();
    await pumpEventQueue();
    snapshots.add(
      _snap(
        TransferPhase.done,
        items: [
          _item(0, 'a.jpg', 100, FileItemStatus.completed),
          _item(1, 'b.pdf', 200, FileItemStatus.completed),
        ],
      ),
    );
    await pumpEventQueue();

    final r =
        verify(() => record(captureAny())).captured.single as TransferRecord;
    expect(r.direction, TransferDirection.received);
    expect(r.status, TransferRecordStatus.completed);
    expect(r.fileCount, 2);
    expect(r.totalBytes, 300);
    expect(r.files.first.path, '/dest/a.jpg');
    await cubit.close();
  });

  test('records a partial record when some files land before a drop', () async {
    final cubit = ReceiveTransferCubit(
      useCase,
      record,
      FakeSettingsRepository(),
      FakeGallerySaver(),
      FakeIncomingFileNotifier(),
    );
    unawaited(cubit.start(_FakeTransport(), senderLabel: 'Người gửi'));
    await pumpEventQueue();
    cubit.accept();
    await pumpEventQueue();
    snapshots.add(
      _snap(
        TransferPhase.failed,
        items: [
          _item(0, 'a.jpg', 100, FileItemStatus.completed),
          _item(1, 'b.pdf', 200, FileItemStatus.failed),
        ],
        failure: const AppFailure.connectionLost(),
      ),
    );
    await pumpEventQueue();

    final r =
        verify(() => record(captureAny())).captured.single as TransferRecord;
    expect(r.status, TransferRecordStatus.partial);
    expect(r.includedFiles.map((f) => f.name), ['a.jpg']);
    await cubit.close();
  });

  test('records NOTHING when the user rejects (FR-001)', () async {
    final cubit = ReceiveTransferCubit(
      useCase,
      record,
      FakeSettingsRepository(),
      FakeGallerySaver(),
      FakeIncomingFileNotifier(),
    );
    unawaited(cubit.start(_FakeTransport(), senderLabel: 'Người gửi'));
    await pumpEventQueue();
    cubit.reject();
    await pumpEventQueue();
    snapshots.add(
      _snap(
        TransferPhase.failed,
        items: const [],
        failure: const AppFailure.transferRejected(),
      ),
    );
    await pumpEventQueue();

    verifyNever(() => record(any()));
    await cubit.close();
  });
}
