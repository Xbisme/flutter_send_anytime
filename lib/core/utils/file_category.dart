import 'package:safe_send/core/domain/history/transfer_record.dart';

/// The three media buckets shown on Home + the See-all screens (#012). The unit
/// of the StatTiles, the recent-media sections, and the See-all destinations.
enum MediaCategory { photos, videos, files }

/// Deterministic, I/O-free categorization of a transferred file into a
/// [MediaCategory] (#012, FR-012). MIME type wins when present; otherwise the
/// file extension is matched against fixed lists; anything not image/video is
/// `files`.
abstract final class FileCategory {
  static const _imageExt = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'heic',
    'heif',
    'bmp',
    'tiff',
  };
  static const _videoExt = <String>{
    'mp4',
    'mov',
    'm4v',
    '3gp',
    'avi',
    'mkv',
    'webm',
  };

  /// Classify [file]. See [FileCategory] for the rule.
  static MediaCategory of(RecordedFile file) {
    final mime = file.mimeType?.trim().toLowerCase() ?? '';
    if (mime.isNotEmpty) {
      if (mime.startsWith('image/')) return MediaCategory.photos;
      if (mime.startsWith('video/')) return MediaCategory.videos;
      return MediaCategory.files;
    }
    final ext = file.ext.toLowerCase(); // ext: upper-case, no dot
    if (_imageExt.contains(ext)) return MediaCategory.photos;
    if (_videoExt.contains(ext)) return MediaCategory.videos;
    return MediaCategory.files;
  }
}
