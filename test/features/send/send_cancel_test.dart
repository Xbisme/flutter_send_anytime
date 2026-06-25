import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';
import 'package:safe_send/features/send/presentation/pages/send_transfer_page.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';

import '../../helpers/fake_record_transfer.dart';
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
      ..registerFactory<SendTransferCubit>(
        () => SendTransferCubit(startSend, FakeRecordTransfer()),
      );
  });
  tearDown(() async {
    await snapshots.close();
    await getIt.reset();
  });

  Future<void> pumpTransferring(WidgetTester tester) async {
    await tester.pumpApp(
      SendTransferPage(
        args: SendProgressArgs(sources: const [], transport: _FakeTransport()),
      ),
      locale: const Locale('en'),
    );
    await tester.pump();
    snapshots.add(
      const TransferSnapshot(
        phase: TransferPhase.transferring,
        role: TransferRole.sender,
        progress: TransferProgress(
          overallBytesTransferred: 50,
          overallTotalBytes: 100,
          currentFileIndex: 0,
        ),
        items: [FileTransferItem(index: 0, name: 'a.bin', size: 100)],
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('cancel asks for confirmation; keeping sending does not cancel', (
    tester,
  ) async {
    await pumpTransferring(tester);

    await tester.tap(find.byType(DangerButton));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Cancel this send?'), findsOneWidget);

    await tester.tap(find.text('Keep sending'));
    await tester.pump(const Duration(milliseconds: 350));
    verifyNever(() => startSend.cancel());
  });

  testWidgets('confirming the dialog cancels the transfer', (tester) async {
    await pumpTransferring(tester);

    await tester.tap(find.byType(DangerButton));
    await tester.pump(const Duration(milliseconds: 350));
    // The dialog's confirm action is a TextButton labelled "Cancel".
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    verify(() => startSend.cancel()).called(1);
  });
}
