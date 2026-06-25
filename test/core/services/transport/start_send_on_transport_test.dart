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

  test(
    'startSendOnTransport reuses the open channel and round-trips a file',
    () async {
      final h = EngineHarness();
      final srcPath = writeTempFile(srcDir, 'photo.jpg', 50000, seed: 1);
      final session = TransferSession.fromSources([DiskFileSource(srcPath)]);

      final senderPhases = <TransferPhase>[];
      h.sender.snapshots.listen((s) => senderPhases.add(s.phase));

      final results = await Future.wait([
        // Sender adopts the already-open transport (no second handshake).
        h.sender.startSendOnTransport(
          transport: h.senderConnector.transport,
          session: session,
        ),
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

      // It runs the same body from handshaking onward.
      expect(
        senderPhases,
        containsAllInOrder([
          TransferPhase.handshaking,
          TransferPhase.transferring,
          TransferPhase.done,
        ]),
      );
    },
  );

  test('multi-file send over an adopted transport completes', () async {
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
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);

    expect(results[0], isA<Success<void>>());
    expect(results[1], isA<Success<void>>());
    expect(File('${dstDir.path}/a.txt').existsSync(), isTrue);
    expect(File('${dstDir.path}/b.bin').existsSync(), isTrue);
  });
}
