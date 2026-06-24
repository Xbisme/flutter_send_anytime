import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/result.dart';
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

  test('single file round-trips byte-identical and both reach done', () async {
    final h = EngineHarness();
    final srcPath = writeTempFile(srcDir, 'photo.jpg', 50000, seed: 1);
    final session = TransferSession.fromSources([DiskFileSource(srcPath)]);

    final senderPhases = <TransferPhase>[];
    h.sender.snapshots.listen((s) => senderPhases.add(s.phase));

    final results = await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(results[0], isA<Success<void>>());
    expect(results[1], isA<Success<void>>());
    expect(h.sender.current.phase, TransferPhase.done);
    expect(h.receiver.current.phase, TransferPhase.done);

    final outPath = '${dstDir.path}/photo.jpg';
    expect(File(outPath).existsSync(), isTrue);
    expect(readBytes(outPath), readBytes(srcPath));

    expect(
      senderPhases,
      containsAllInOrder([
        TransferPhase.connecting,
        TransferPhase.handshaking,
        TransferPhase.transferring,
        TransferPhase.done,
      ]),
    );
  });

  test('progress is monotonic and reaches 100% of total', () async {
    final h = EngineHarness();
    final srcPath = writeTempFile(srcDir, 'big.bin', 200000, seed: 2);
    final session = TransferSession.fromSources([DiskFileSource(srcPath)]);

    var lastOverall = 0;
    var monotonic = true;
    h.sender.snapshots.listen((s) {
      if (s.progress.overallBytesTransferred < lastOverall) monotonic = false;
      lastOverall = s.progress.overallBytesTransferred;
    });

    await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(monotonic, isTrue);
    expect(lastOverall, 200000);
  });

  test('no quarantine .part artifacts remain after success', () async {
    final h = EngineHarness();
    final srcPath = writeTempFile(srcDir, 'doc.pdf', 8000, seed: 3);
    final session = TransferSession.fromSources([DiskFileSource(srcPath)]);

    await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    final quarantine = Directory('${dstDir.path}/.safesend_tmp');
    expect(quarantine.existsSync(), isFalse);
    expect(File('${dstDir.path}/doc.pdf').existsSync(), isTrue);
  });

  test(
    'snapshots stream closes after a terminal phase (clean teardown)',
    () async {
      final h = EngineHarness();
      final srcPath = writeTempFile(srcDir, 'a.txt', 1234, seed: 4);
      final session = TransferSession.fromSources([DiskFileSource(srcPath)]);

      final done = expectLater(h.sender.snapshots, emitsThrough(emitsDone));

      await Future.wait([
        h.sender.startSend(session: session, signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);
      await done;
      // Disposing again is safe/idempotent.
      await h.sender.dispose();
    },
  );
}
