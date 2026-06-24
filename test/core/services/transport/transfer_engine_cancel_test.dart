import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';

import '../../../helpers/engine_harness.dart';
import '../../../helpers/temp_files.dart';

void main() {
  late Directory srcDir;
  late Directory dstDir;

  setUp(() {
    srcDir = createTempDir('src');
    dstDir = createTempDir('dst');
  });
  tearDown(() {
    if (srcDir.existsSync()) srcDir.deleteSync(recursive: true);
    if (dstDir.existsSync()) dstDir.deleteSync(recursive: true);
  });

  TransferSession bigSession() => TransferSession.fromSources([
    DiskFileSource(writeTempFile(srcDir, 'big.bin', 1 << 20, seed: 7)),
  ]);

  test(
    'cancel from sender → both cancelled, nothing left at destination',
    () async {
      final h = EngineHarness(latency: const Duration(microseconds: 300));
      var triggered = false;
      h.sender.snapshots.listen((s) {
        if (!triggered &&
            s.phase == TransferPhase.transferring &&
            s.progress.overallBytesTransferred > 0) {
          triggered = true;
          unawaited(h.sender.cancel());
        }
      });

      await Future.wait([
        h.sender.startSend(session: bigSession(), signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);

      expect(h.sender.current.phase, TransferPhase.cancelled);
      expect(h.receiver.current.phase, TransferPhase.cancelled);
      expect(dstDir.listSync(), isEmpty);
    },
  );

  test(
    'cancel from receiver → both cancelled, nothing left at destination',
    () async {
      final h = EngineHarness(latency: const Duration(microseconds: 300));
      var triggered = false;
      h.receiver.snapshots.listen((s) {
        if (!triggered &&
            s.phase == TransferPhase.transferring &&
            s.progress.overallBytesTransferred > 0) {
          triggered = true;
          unawaited(h.receiver.cancel());
        }
      });

      await Future.wait([
        h.sender.startSend(session: bigSession(), signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);

      expect(h.sender.current.phase, TransferPhase.cancelled);
      expect(h.receiver.current.phase, TransferPhase.cancelled);
      expect(dstDir.listSync(), isEmpty);
    },
  );

  test('cancel before any bytes flow still tears down cleanly', () async {
    final h = EngineHarness();
    final fut = Future.wait([
      h.sender.startSend(session: bigSession(), signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);
    await h.receiver.cancel();
    await fut;

    expect(h.receiver.current.phase, TransferPhase.cancelled);
    expect(dstDir.listSync(), isEmpty);
  });
}
