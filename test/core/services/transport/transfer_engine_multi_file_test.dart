import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';

import '../../../helpers/corrupting_transport.dart';
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

  test('multiple files transfer in order, all byte-identical', () async {
    final h = EngineHarness();
    final paths = [
      writeTempFile(srcDir, 'f0.bin', 30000),
      writeTempFile(srcDir, 'f1.bin', 12000, seed: 1),
      writeTempFile(srcDir, 'f2.bin', 45000, seed: 2),
    ];
    final session = TransferSession.fromSources(
      paths.map(DiskFileSource.new).toList(),
    );

    final results = await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(results.every((r) => r is Success<void>), isTrue);
    for (final name in ['f0.bin', 'f1.bin', 'f2.bin']) {
      final out = '${dstDir.path}/$name';
      expect(File(out).existsSync(), isTrue, reason: name);
      expect(readBytes(out), readBytes('${srcDir.path}/$name'));
    }
    expect(h.receiver.current.progress.overallBytesTransferred, 87000);
  });

  test(
    'fail-fast: a corrupt file fails the whole session, no files placed',
    () async {
      final h = CorruptingHarness();
      final paths = [
        writeTempFile(srcDir, 'f0.bin', 40000),
        writeTempFile(srcDir, 'f1.bin', 40000, seed: 1),
        writeTempFile(srcDir, 'f2.bin', 40000, seed: 2),
      ];
      final session = TransferSession.fromSources(
        paths.map(DiskFileSource.new).toList(),
      );

      final results = await Future.wait([
        h.sender.startSend(session: session, signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);

      expect(results[1], isA<Failure<void>>());
      expect(h.receiver.current.phase, TransferPhase.failed);
      expect(
        h.receiver.current.failure,
        const AppFailure.integrityCheckFailed(fileIndex: 0),
      );
      // No completed files and no quarantine leftovers at the destination.
      expect(dstDir.listSync(), isEmpty);
    },
  );

  test('filename collisions auto-rename, never overwrite', () async {
    final h = EngineHarness();
    final subDir = Directory('${srcDir.path}/sub')..createSync();
    final p0 = writeTempFile(srcDir, 'a.txt', 1000, seed: 10);
    final p1 = writeTempFile(subDir, 'a.txt', 2000, seed: 20);
    final session = TransferSession.fromSources([
      DiskFileSource(p0),
      DiskFileSource(p1),
    ]);

    await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(readBytes('${dstDir.path}/a.txt'), readBytes(p0));
    expect(readBytes('${dstDir.path}/a (1).txt'), readBytes(p1));
  });

  test('a pre-existing destination file is never overwritten', () async {
    final h = EngineHarness();
    File('${dstDir.path}/a.txt').writeAsStringSync('SENTINEL');
    final p0 = writeTempFile(srcDir, 'a.txt', 1500, seed: 30);
    final session = TransferSession.fromSources([DiskFileSource(p0)]);

    await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(File('${dstDir.path}/a.txt').readAsStringSync(), 'SENTINEL');
    expect(readBytes('${dstDir.path}/a (1).txt'), readBytes(p0));
  });
}
