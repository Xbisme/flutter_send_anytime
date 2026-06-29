import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/media/video_thumbnail_service.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:video_thumbnail_plus/video_thumbnail_plus.dart';

/// Generates a JPEG thumbnail for [video] into [dir]; returns its path or null.
typedef ThumbnailGenerator = Future<String?> Function(String video, String dir);

/// Default [VideoThumbnailService] (#013, US4): `video_thumbnail_plus` +
/// a disk LRU cache keyed by `path + mtime` so a frame is decoded at most once
/// per video and survives across sessions (FR-013a). Logs no path (Principle I).
@LazySingleton(as: VideoThumbnailService)
class VideoThumbnailServiceImpl implements VideoThumbnailService {
  /// DI constructor (no params so injectable can register it).
  VideoThumbnailServiceImpl()
    : _generate = _platformGenerate,
      _cacheDirProvider = getApplicationCacheDirectory;

  /// Test seam: inject a fake generator + cache dir.
  @visibleForTesting
  VideoThumbnailServiceImpl.test({
    required ThumbnailGenerator generator,
    required Future<Directory> Function() cacheDirProvider,
  }) : _generate = generator,
       _cacheDirProvider = cacheDirProvider;

  static const _subdir = 'video_thumbs';

  final ThumbnailGenerator _generate;
  final Future<Directory> Function() _cacheDirProvider;

  static Future<String?> _platformGenerate(String video, String dir) {
    return VideoThumbnailPlus.thumbnailFile(
      video: video,
      thumbnailPath: dir,
      imageFormat: ImageFormat.JPEG,
      maxWidth: kVideoThumbMaxWidth,
      quality: 75,
    );
  }

  @override
  Future<Result<String?>> thumbnailPath(String videoPath) async {
    try {
      final src = File(videoPath);
      if (!src.existsSync()) return const Result.success(null);

      final mtime = src.statSync().modified.millisecondsSinceEpoch;
      final key = sha1.convert(utf8.encode('$videoPath|$mtime')).toString();

      final base = await _cacheDirProvider();
      final dir = Directory('${base.path}${Platform.pathSeparator}$_subdir');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final cached = File('${dir.path}${Platform.pathSeparator}$key.jpg');

      if (cached.existsSync()) {
        cached.setLastModifiedSync(DateTime.now()); // LRU recency
        return Result.success(cached.path);
      }

      final generated = await _generate(videoPath, dir.path);
      if (generated == null) return const Result.success(null);
      final genFile = File(generated);
      if (genFile.path != cached.path) {
        if (cached.existsSync()) cached.deleteSync();
        await genFile.rename(cached.path);
      }
      _enforceLru(dir);
      return Result.success(cached.path);
    } on Object catch (error) {
      AppLogger.error('video thumbnail failed (${error.runtimeType})');
      return const Result.failure(AppFailure.unexpected(message: 'thumbnail'));
    }
  }

  /// Evict least-recently-modified thumbnails until the cache is within
  /// [kVideoThumbCacheMaxBytes].
  void _enforceLru(Directory dir) {
    final files = dir.listSync().whereType<File>().toList()
      ..sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
    var total = files.fold<int>(0, (sum, f) => sum + f.lengthSync());
    for (final file in files) {
      if (total <= kVideoThumbCacheMaxBytes) break;
      final size = file.lengthSync();
      try {
        file.deleteSync();
        total -= size;
      } on Object {
        // Best-effort eviction; ignore a file we cannot delete.
      }
    }
  }
}
