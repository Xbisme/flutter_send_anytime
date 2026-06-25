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

  test('round-trips a single file over both adopted transports', () async {
    final h = EngineHarness();
    final src = writeTempFile(srcDir, 'photo.jpg', 50000, seed: 1);
    final session = TransferSession.fromSources([DiskFileSource(src)]);

    final phases = <TransferPhase>[];
    h.receiver.snapshots.listen((s) => phases.add(s.phase));

    final results = await Future.wait([
      h.sender.startSendOnTransport(
        transport: h.senderConnector.transport,
        session: session,
      ),
      h.receiver.startReceiveOnTransport(
        transport: h.receiverConnector.transport,
        destinationDir: dstDir,
      ),
    ]);

    expect(results[0], isA<Success<void>>());
    expect(results[1], isA<Success<void>>());
    expect(h.receiver.current.phase, TransferPhase.done);

    final out = '${dstDir.path}/photo.jpg';
    expect(File(out).existsSync(), isTrue);
    expect(readBytes(out), readBytes(src));
    expect(
      phases,
      containsAllInOrder([
        TransferPhase.handshaking,
        TransferPhase.transferring,
        TransferPhase.done,
      ]),
    );
  });

  test('round-trips multiple files', () async {
    final h = EngineHarness();
    final a = writeTempFile(srcDir, 'a.txt', 4000, seed: 2);
    final b = writeTempFile(srcDir, 'b.bin', 9000, seed: 3);
    final session = TransferSession.fromSources([
      DiskFileSource(a),
      DiskFileSource(b),
    ]);

    final results = await Future.wait([
      h.sender.startSendOnTransport(
        transport: h.senderConnector.transport,
        session: session,
      ),
      h.receiver.startReceiveOnTransport(
        transport: h.receiverConnector.transport,
        destinationDir: dstDir,
      ),
    ]);

    expect(results[0], isA<Success<void>>());
    expect(results[1], isA<Success<void>>());
    expect(File('${dstDir.path}/a.txt').existsSync(), isTrue);
    expect(File('${dstDir.path}/b.bin').existsSync(), isTrue);
  });

  test('a same-named file is saved without overwriting (FR-017)', () async {
    final h = EngineHarness();
    final srcDir2 = createTempDir('src2');
    final a = writeTempFile(srcDir, 'dup.bin', 4000, seed: 4);
    final b = writeTempFile(srcDir2, 'dup.bin', 6000, seed: 5);
    final session = TransferSession.fromSources([
      DiskFileSource(a),
      DiskFileSource(b),
    ]);

    await Future.wait([
      h.sender.startSendOnTransport(
        transport: h.senderConnector.transport,
        session: session,
      ),
      h.receiver.startReceiveOnTransport(
        transport: h.receiverConnector.transport,
        destinationDir: dstDir,
      ),
    ]);

    final files = dstDir.listSync().whereType<File>().toList();
    expect(files.length, 2, reason: 'both files kept, none overwritten');
    srcDir2.deleteSync(recursive: true);
  });
}
