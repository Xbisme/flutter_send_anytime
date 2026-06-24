import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';

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

  Future<int> runAndPeak(int fileSize) async {
    final h = EngineHarness(latency: const Duration(microseconds: 400));
    final src = writeTempFile(srcDir, 'big.bin', fileSize, seed: 1);
    final session = TransferSession.fromSources([DiskFileSource(src)]);
    final results = await Future.wait([
      h.sender.startSend(session: session, signaling: h.senderSignaling),
      h.receiver.startReceive(
        signaling: h.receiverSignaling,
        destinationDir: dstDir,
      ),
    ]);
    expect(results.every((r) => r is Success<void>), isTrue);
    expect(
      readBytes('${dstDir.path}/big.bin'),
      readBytes(src),
      reason: 'completes intact',
    );
    return h.senderConnector.transport.peakBufferedAmount;
  }

  test('a slow consumer makes the sender respect backpressure', () async {
    final peak = await runAndPeak(3 * 1024 * 1024);
    expect(
      peak,
      lessThanOrEqualTo(
        TransferConstants.kHighWaterMark + TransferConstants.kChunkSize,
      ),
      reason: 'sender pauses above the high-water mark',
    );
  });

  test('peak memory does not scale with file size (bounded budget)', () async {
    final small = await runAndPeak(2 * 1024 * 1024);
    dstDir
      ..deleteSync(recursive: true)
      ..createSync();
    final large = await runAndPeak(6 * 1024 * 1024);
    const bound =
        TransferConstants.kHighWaterMark + TransferConstants.kChunkSize;
    // Tripling the file size does not raise the peak buffer past the bound.
    expect(small, lessThanOrEqualTo(bound));
    expect(large, lessThanOrEqualTo(bound));
  });
}
