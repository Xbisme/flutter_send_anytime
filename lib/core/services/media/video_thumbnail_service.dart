import 'package:safe_send/core/domain/result.dart';

/// Generates + caches first-frame thumbnails for video tiles (#013, US4).
// ignore: one_member_abstracts
abstract class VideoThumbnailService {
  /// A cached/generated thumbnail JPEG path for [videoPath], or `null` when no
  /// thumbnail is possible (corrupt video, generation unavailable). Never
  /// throws — failures map to a [Result] failure; callers fall back to the
  /// play-glyph placeholder (FR-013).
  Future<Result<String?>> thumbnailPath(String videoPath);
}
