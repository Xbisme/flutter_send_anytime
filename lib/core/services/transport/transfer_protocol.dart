import 'dart:convert';
import 'dart:typed_data';

import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';

/// Thrown when an incoming frame is malformed or unexpected. The engine catches
/// it and maps it to a typed failure (FR-015) — it never escapes as a crash.
class ProtocolException implements Exception {
  const ProtocolException(this.reason);

  /// A short machine reason code (never user-facing, never sensitive).
  final String reason;

  @override
  String toString() => 'ProtocolException($reason)';
}

/// A decoded protocol frame.
sealed class ProtocolFrame {
  const ProtocolFrame();
}

/// Session manifest frame.
class ManifestFrame extends ProtocolFrame {
  const ManifestFrame(this.manifest);
  final TransferManifest manifest;
}

/// Manifest-accepted frame.
class AcceptFrame extends ProtocolFrame {
  const AcceptFrame(this.sessionId);
  final String sessionId;
}

/// Manifest-rejected frame.
class RejectFrame extends ProtocolFrame {
  const RejectFrame(this.sessionId);
  final String sessionId;
}

/// Start-of-file frame.
class FileStartFrame extends ProtocolFrame {
  const FileStartFrame({
    required this.index,
    required this.name,
    required this.size,
  });
  final int index;
  final String name;
  final int size;
}

/// Raw file-bytes frame.
class ChunkFrame extends ProtocolFrame {
  const ChunkFrame(this.bytes);
  final Uint8List bytes;
}

/// End-of-file frame carrying the per-file SHA-256.
class FileCompleteFrame extends ProtocolFrame {
  const FileCompleteFrame({required this.index, required this.sha256});
  final int index;
  final String sha256;
}

/// All-files-done frame.
class SessionCompleteFrame extends ProtocolFrame {
  const SessionCompleteFrame(this.sessionId);
  final String sessionId;
}

/// Cancel/abort frame.
class CancelFrame extends ProtocolFrame {
  const CancelFrame({required this.sessionId, required this.origin});
  final String sessionId;
  final String origin;
}

/// Encodes/decodes the `[1-byte opcode][payload]` wire protocol. Pure Dart and
/// fully unit-testable without WebRTC (Constitution VIII).
abstract final class TransferProtocol {
  static Uint8List _frame(int opcode, List<int> payload) {
    final out = Uint8List(payload.length + 1);
    out[0] = opcode;
    out.setRange(1, out.length, payload);
    return out;
  }

  static Uint8List _jsonFrame(int opcode, Map<String, dynamic> map) =>
      _frame(opcode, utf8.encode(jsonEncode(map)));

  /// Encode a manifest frame.
  static Uint8List encodeManifest(TransferManifest manifest) =>
      _jsonFrame(TransferOpcode.manifest, manifest.toJson());

  /// Encode an accept frame.
  static Uint8List encodeAccept(String sessionId) =>
      _jsonFrame(TransferOpcode.accept, {'sessionId': sessionId});

  /// Encode a reject frame.
  static Uint8List encodeReject(String sessionId) =>
      _jsonFrame(TransferOpcode.reject, {'sessionId': sessionId});

  /// Encode a file-start frame.
  static Uint8List encodeFileStart({
    required int index,
    required String name,
    required int size,
  }) => _jsonFrame(TransferOpcode.fileStart, {
    'index': index,
    'name': name,
    'size': size,
  });

  /// Encode a raw-bytes chunk frame.
  static Uint8List encodeChunk(List<int> bytes) =>
      _frame(TransferOpcode.chunk, bytes);

  /// Encode a file-complete frame (carries the per-file SHA-256).
  static Uint8List encodeFileComplete({
    required int index,
    required String sha256,
  }) => _jsonFrame(TransferOpcode.fileComplete, {
    'index': index,
    'sha256': sha256,
  });

  /// Encode a session-complete frame.
  static Uint8List encodeSessionComplete(String sessionId) =>
      _jsonFrame(TransferOpcode.sessionComplete, {'sessionId': sessionId});

  /// Encode a cancel frame.
  static Uint8List encodeCancel({
    required String sessionId,
    required String origin,
  }) => _jsonFrame(TransferOpcode.cancel, {
    'sessionId': sessionId,
    'origin': origin,
  });

  /// Decode a frame. Throws [ProtocolException] on any malformed/unknown input.
  static ProtocolFrame decode(Uint8List frame) {
    if (frame.isEmpty) throw const ProtocolException('empty');
    final opcode = frame[0];
    final payload = Uint8List.sublistView(frame, 1);
    if (opcode == TransferOpcode.chunk) {
      return ChunkFrame(Uint8List.fromList(payload));
    }
    try {
      final map = _decodeJson(payload);
      switch (opcode) {
        case TransferOpcode.manifest:
          return ManifestFrame(TransferManifest.fromJson(map));
        case TransferOpcode.accept:
          return AcceptFrame(map['sessionId'] as String);
        case TransferOpcode.reject:
          return RejectFrame(map['sessionId'] as String);
        case TransferOpcode.fileStart:
          return FileStartFrame(
            index: map['index'] as int,
            name: map['name'] as String,
            size: map['size'] as int,
          );
        case TransferOpcode.fileComplete:
          return FileCompleteFrame(
            index: map['index'] as int,
            sha256: map['sha256'] as String,
          );
        case TransferOpcode.sessionComplete:
          return SessionCompleteFrame(map['sessionId'] as String);
        case TransferOpcode.cancel:
          return CancelFrame(
            sessionId: map['sessionId'] as String,
            origin: map['origin'] as String,
          );
        default:
          throw ProtocolException('opcode:$opcode');
      }
    } on ProtocolException {
      rethrow;
    } on Object {
      throw ProtocolException('decode:$opcode');
    }
  }

  static Map<String, dynamic> _decodeJson(Uint8List payload) {
    final decoded = jsonDecode(utf8.decode(payload));
    if (decoded is! Map<String, dynamic>) {
      throw const ProtocolException('json');
    }
    return decoded;
  }
}
