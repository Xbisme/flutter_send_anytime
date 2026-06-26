import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';

part 'transfer_manifest.freezed.dart';
part 'transfer_manifest.g.dart';

/// One file's metadata inside a [TransferManifest]. No hash — the per-file
/// SHA-256 travels in the `fileComplete` frame (research R-04).
@freezed
abstract class ManifestFileEntry with _$ManifestFileEntry {
  const factory ManifestFileEntry({
    required int index,
    required String name,
    required int size,
    String? mime,
  }) = _ManifestFileEntry;

  factory ManifestFileEntry.fromJson(Map<String, dynamic> json) =>
      _$ManifestFileEntryFromJson(json);
}

/// The session manifest, sent once before any bytes flow. Basis for the
/// receiver's accept/reject decision (FR-012).
@freezed
abstract class TransferManifest with _$TransferManifest {
  const factory TransferManifest({
    required int v,
    required String sessionId,
    required int fileCount,
    required int totalBytes,
    required List<ManifestFileEntry> files,
    // Sender's device name (#010, optional + backward-compatible: absent ⇒ the
    // receiver shows a generic localized label). Never logged (Principle I).
    String? senderName,
  }) = _TransferManifest;

  const TransferManifest._();

  factory TransferManifest.fromJson(Map<String, dynamic> json) =>
      _$TransferManifestFromJson(json);

  /// Returns null if the manifest is structurally valid, otherwise a short
  /// machine reason code. Validation covers version, counts, sizes, and
  /// path-traversal in file names (FR-015/023).
  String? validationError() {
    if (v != TransferConstants.kProtocolVersion) return 'version';
    if (fileCount != files.length) return 'count';
    if (totalBytes < 0) return 'totalBytes';
    var sum = 0;
    for (final f in files) {
      if (f.size < 0) return 'size';
      if (!_isSafeName(f.name)) return 'unsafeName';
      sum += f.size;
    }
    if (sum != totalBytes) return 'totalBytesMismatch';
    return null;
  }

  /// A safe destination name is a non-empty basename with no path separators,
  /// no `..` traversal, and is not absolute.
  static bool _isSafeName(String name) {
    if (name.isEmpty) return false;
    if (name.trim().isEmpty) return false;
    if (name.contains('/') || name.contains(r'\')) return false;
    if (name == '.' || name == '..') return false;
    return true;
  }
}
