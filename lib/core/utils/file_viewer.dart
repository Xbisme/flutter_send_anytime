import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/utils/file_category.dart';

/// Which in-app viewer a tapped file routes to (#013). Supersedes
/// [FileCategory] for *routing* — audio, PDF, and text/code split out of its
/// `files` bucket — while reusing its image/video sets.
enum ViewerKind { image, video, audio, pdf, text, unsupported }

/// Pure, I/O-free classification of a file → [ViewerKind] (FR-002). MIME wins
/// when present; otherwise the lower-cased extension is matched against the
/// fixed sets. Anything unrecognized is [ViewerKind.unsupported] → the caller
/// falls back to the OS open/share handoff (FR-004).
abstract final class ViewerResolver {
  /// Resolve [name] (with optional [mimeType]) to a [ViewerKind].
  static ViewerKind of(String name, {String? mimeType}) {
    final mime = mimeType?.trim().toLowerCase() ?? '';
    if (mime.isNotEmpty) {
      if (mime.startsWith('image/')) return ViewerKind.image;
      if (mime.startsWith('video/')) return ViewerKind.video;
      if (mime.startsWith('audio/')) return ViewerKind.audio;
      if (mime == 'application/pdf') return ViewerKind.pdf;
      if (mime.startsWith('text/')) return ViewerKind.text;
      // Known non-text application types fall through to extension matching
      // below so e.g. application/json still resolves to text.
    }
    final ext = _ext(name);
    if (ext.isEmpty) return ViewerKind.unsupported;
    if (FileCategory.imageExts.contains(ext)) return ViewerKind.image;
    if (FileCategory.videoExts.contains(ext)) return ViewerKind.video;
    if (kAudioExts.contains(ext)) return ViewerKind.audio;
    if (kPdfExts.contains(ext)) return ViewerKind.pdf;
    if (kTextExts.contains(ext)) return ViewerKind.text;
    return ViewerKind.unsupported;
  }

  /// Whether [kind] opens an in-app viewer (everything except
  /// [ViewerKind.unsupported]).
  static bool isViewable(ViewerKind kind) => kind != ViewerKind.unsupported;

  /// Lower-case extension of [name] without the dot (`'a.PNG'` → `'png'`).
  static String _ext(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }
}
