import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart';
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart';

import '../../helpers/fake_record_transfer.dart';
import '../../helpers/settings_fakes.dart';

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
  fileCount: 1,
  totalBytes: 100,
  files: [ManifestFileEntry(index: 0, name: 'a.jpg', size: 100)],
);

void main() {
  // The auto-receive seam reads WidgetsBinding.instance.lifecycleState.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockStartReceive useCase;
  late StreamController<TransferSnapshot> snapshots;
  late bool? decision;

  setUpAll(() => registerFallbackValue(_FakeTransport()));

  setUp(() {
    useCase = _MockStartReceive();
    snapshots = StreamController<TransferSnapshot>.broadcast();
    decision = null;
    when(() => useCase.snapshots).thenAnswer((_) => snapshots.stream);
    when(() => useCase.dispose()).thenAnswer((_) async {});
    when(
      () => useCase(
        transport: any(named: 'transport'),
        onManifest: any(named: 'onManifest'),
      ),
    ).thenAnswer((inv) async {
      final onManifest =
          inv.namedArguments[#onManifest]
              as Future<bool> Function(TransferManifest);
      decision = await onManifest(_manifest);
      return const Result.success(null);
    });
  });
  tearDown(() async => snapshots.close());

  ReceiveTransferCubit build(AppSettings settings) => ReceiveTransferCubit(
    useCase,
    FakeRecordTransfer(),
    FakeSettingsRepository(settings),
    FakeGallerySaver(),
    FakeIncomingFileNotifier(),
  );

  test(
    'auto-receive ON + foreground auto-accepts without the prompt (FR-007)',
    () async {
      final cubit = build(
        const AppSettings(deviceName: 'D', autoReceive: true),
      );
      await cubit.start(_FakeTransport(), senderLabel: 'Người gửi');
      await pumpEventQueue();

      expect(decision, isTrue); // gate resolved true with no accept() call
      await cubit.close();
    },
  );

  test('auto-receive OFF still shows the prompt (decision pending)', () async {
    final cubit = build(const AppSettings(deviceName: 'D'));
    unawaited(cubit.start(_FakeTransport(), senderLabel: 'Người gửi'));
    await pumpEventQueue();

    expect(decision, isNull); // waiting for the user
    cubit.reject();
    await pumpEventQueue();
    expect(decision, isFalse);
    await cubit.close();
  });

  test('save-to-library copies completed media on terminal (FR-008)', () async {
    final saver = FakeGallerySaver();
    final cubit = ReceiveTransferCubit(
      useCase,
      FakeRecordTransfer(),
      FakeSettingsRepository(
        const AppSettings(
          deviceName: 'D',
          autoReceive: true,
          saveToLibrary: true,
        ),
      ),
      saver,
      FakeIncomingFileNotifier(),
    );
    await cubit.start(_FakeTransport(), senderLabel: 'P');
    await pumpEventQueue();

    snapshots.add(
      const TransferSnapshot(
        phase: TransferPhase.done,
        role: TransferRole.receiver,
        progress: TransferProgress(
          overallBytesTransferred: 100,
          overallTotalBytes: 100,
        ),
        items: [
          FileTransferItem(
            index: 0,
            name: 'a.jpg',
            size: 100,
            status: FileItemStatus.completed,
            finalPath: '/tmp/a.jpg',
          ),
        ],
      ),
    );
    await pumpEventQueue();

    expect(saver.saved, contains('/tmp/a.jpg'));
    await cubit.close();
  });
}
