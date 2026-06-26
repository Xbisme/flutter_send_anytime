import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:uuid/uuid.dart';

/// A unit of work moving one or more files between two peers. Owns exactly one
/// manifest's worth of files, transferred sequentially in order.
class TransferSession {
  TransferSession({required this.id, required this.sources, this.senderName})
    : assert(sources.isNotEmpty, 'a session needs at least one file');

  /// Build a session from disk-backed (or other) [FileSource]s. [senderName] is
  /// this device's display name (#010), carried in the manifest to the peer.
  factory TransferSession.fromSources(
    List<FileSource> sources, {
    String? senderName,
  }) => TransferSession(
    id: const Uuid().v4(),
    sources: sources,
    senderName: senderName,
  );

  /// Session identifier (UUID v4).
  final String id;

  /// The files to transfer, in order.
  final List<FileSource> sources;

  /// This device's display name shown to the receiver (#010), or null.
  final String? senderName;

  /// Total bytes across all files.
  int get totalBytes => sources.fold(0, (sum, s) => sum + s.size);

  /// Number of files in the session.
  int get fileCount => sources.length;

  /// The initial per-file items (all `pending`).
  List<FileTransferItem> initialItems() => [
    for (var i = 0; i < sources.length; i++)
      FileTransferItem(
        index: i,
        name: sources[i].name,
        size: sources[i].size,
        mimeType: sources[i].mimeType,
      ),
  ];

  /// The manifest describing this session (sent before bytes flow).
  TransferManifest toManifest() => TransferManifest(
    v: TransferConstants.kProtocolVersion,
    sessionId: id,
    fileCount: fileCount,
    totalBytes: totalBytes,
    senderName: senderName,
    files: [
      for (var i = 0; i < sources.length; i++)
        ManifestFileEntry(
          index: i,
          name: sources[i].name,
          size: sources[i].size,
          mime: sources[i].mimeType,
        ),
    ],
  );
}
