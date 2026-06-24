import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/services/transport/transfer_protocol.dart';

void main() {
  group('TransferProtocol framing round-trips', () {
    test('manifest', () {
      const manifest = TransferManifest(
        v: TransferConstants.kProtocolVersion,
        sessionId: 's1',
        fileCount: 1,
        totalBytes: 10,
        files: [ManifestFileEntry(index: 0, name: 'a.txt', size: 10)],
      );
      final frame = TransferProtocol.decode(
        TransferProtocol.encodeManifest(manifest),
      );
      expect(frame, isA<ManifestFrame>());
      expect((frame as ManifestFrame).manifest, manifest);
    });

    test('accept / reject / sessionComplete', () {
      expect(
        (TransferProtocol.decode(TransferProtocol.encodeAccept('s'))
                as AcceptFrame)
            .sessionId,
        's',
      );
      expect(
        (TransferProtocol.decode(TransferProtocol.encodeReject('s'))
                as RejectFrame)
            .sessionId,
        's',
      );
      expect(
        (TransferProtocol.decode(TransferProtocol.encodeSessionComplete('s'))
                as SessionCompleteFrame)
            .sessionId,
        's',
      );
    });

    test('fileStart / fileComplete', () {
      final start =
          TransferProtocol.decode(
                TransferProtocol.encodeFileStart(
                  index: 2,
                  name: 'x.bin',
                  size: 99,
                ),
              )
              as FileStartFrame;
      expect(start.index, 2);
      expect(start.name, 'x.bin');
      expect(start.size, 99);

      final done =
          TransferProtocol.decode(
                TransferProtocol.encodeFileComplete(index: 2, sha256: 'abc'),
              )
              as FileCompleteFrame;
      expect(done.index, 2);
      expect(done.sha256, 'abc');
    });

    test('cancel', () {
      final cancel =
          TransferProtocol.decode(
                TransferProtocol.encodeCancel(sessionId: 's', origin: 'sender'),
              )
              as CancelFrame;
      expect(cancel.sessionId, 's');
      expect(cancel.origin, 'sender');
    });

    test('chunk carries raw bytes verbatim', () {
      final payload = Uint8List.fromList([0, 1, 2, 255, 128]);
      final frame =
          TransferProtocol.decode(TransferProtocol.encodeChunk(payload))
              as ChunkFrame;
      expect(frame.bytes, payload);
    });
  });

  group('TransferProtocol rejects malformed input', () {
    test('empty frame', () {
      expect(
        () => TransferProtocol.decode(Uint8List(0)),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('unknown opcode', () {
      expect(
        () => TransferProtocol.decode(Uint8List.fromList([0xFF, 1, 2, 3])),
        throwsA(isA<ProtocolException>()),
      );
    });

    test('malformed JSON payload', () {
      final bad = Uint8List.fromList([
        TransferOpcode.accept,
        ...utf8.encode('{not json'),
      ]);
      expect(
        () => TransferProtocol.decode(bad),
        throwsA(isA<ProtocolException>()),
      );
    });
  });
}
