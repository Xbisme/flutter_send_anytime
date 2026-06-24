import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/loopback_signaling_channel.dart';
import 'package:safe_send/core/services/transport/loopback_data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_engine.dart';
import 'package:safe_send/core/services/transport/transfer_protocol.dart';

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

  test('receiver rejects the manifest → transferRejected, no files', () async {
    final h = EngineHarness();
    final session = TransferSession.fromSources([
      DiskFileSource(writeTempFile(srcDir, 'a.bin', 4000, seed: 1)),
    ]);

    final results = await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
        onManifest: (_) async => false,
      ),
    ]);

    expect(results[0], isA<Failure<void>>());
    expect(h.sender.current.failure, const AppFailure.transferRejected());
    expect(h.receiver.current.phase, TransferPhase.failed);
    expect(dstDir.listSync(), isEmpty);
  });

  test(
    'corrupted chunk → integrityCheckFailed, nothing at destination',
    () async {
      final h = CorruptingHarness();
      final session = TransferSession.fromSources([
        DiskFileSource(writeTempFile(srcDir, 'a.bin', 50000, seed: 1)),
      ]);

      final results = await Future.wait([
        h.sender.startSend(session: session, signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);

      expect(results[1], isA<Failure<void>>());
      expect(
        h.receiver.current.failure,
        const AppFailure.integrityCheckFailed(fileIndex: 0),
      );
      expect(dstDir.listSync(), isEmpty);
    },
  );

  test(
    'malformed manifest (bad version) is rejected, no crash, no files',
    () async {
      final result = await _receiveCraftedManifest(
        dstDir,
        const TransferManifest(
          v: 999,
          sessionId: 's',
          fileCount: 1,
          totalBytes: 5,
          files: [ManifestFileEntry(index: 0, name: 'a.txt', size: 5)],
        ),
      );
      expect(result.phase, TransferPhase.failed);
      expect(dstDir.listSync(), isEmpty);
    },
  );

  test('path-traversal file name in manifest is rejected, no write', () async {
    final result = await _receiveCraftedManifest(
      dstDir,
      const TransferManifest(
        v: 1,
        sessionId: 's',
        fileCount: 1,
        totalBytes: 5,
        files: [ManifestFileEntry(index: 0, name: '../evil.txt', size: 5)],
      ),
    );
    expect(result.phase, TransferPhase.failed);
    expect(dstDir.listSync(), isEmpty);
  });

  test(
    'peer disconnect mid-transfer → connectionLost within bounded time',
    () async {
      final h = EngineHarness(latency: const Duration(microseconds: 300));
      final session = TransferSession.fromSources([
        DiskFileSource(writeTempFile(srcDir, 'big.bin', 1 << 20, seed: 9)),
      ]);
      var dropped = false;
      h.receiver.snapshots.listen((s) {
        if (!dropped &&
            s.phase == TransferPhase.transferring &&
            s.progress.overallBytesTransferred > 0) {
          dropped = true;
          h.senderConnector.transport.drop();
        }
      });

      await Future.wait([
        h.sender.startSend(session: session, signaling: h.senderSignaling),
        h.receiver.startReceive(
          signaling: h.receiverSignaling,
          destinationDir: dstDir,
        ),
      ]);

      expect(h.receiver.current.phase, TransferPhase.failed);
      expect(h.receiver.current.failure, const AppFailure.connectionLost());
      expect(dstDir.listSync(), isEmpty);
    },
  );
}

/// Drives a receiver against a hand-crafted (invalid) manifest pushed over a
/// raw loopback transport, returning the receiver's terminal snapshot.
Future<TransferSnapshot> _receiveCraftedManifest(
  Directory dstDir,
  TransferManifest manifest,
) async {
  final (a, b) = LoopbackDataTransport.pair();
  final (_, rs) = LoopbackSignalingChannel.pair();
  const config = AppConfig(flavor: AppFlavor.dev);
  final receiver = TransferEngine(FixedPeerConnector(b), config);
  final fut = receiver.startReceive(signaling: rs, destinationDir: dstDir);
  await Future<void>.delayed(Duration.zero);
  await a.send(TransferProtocol.encodeManifest(manifest));
  await fut;
  return receiver.current;
}
