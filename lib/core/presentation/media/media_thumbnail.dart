import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/services/media/video_thumbnail_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/core/utils/received_file_path.dart';

/// Fills a media grid cell (#012/#013). A photo whose file is on disk shows a
/// real decoded thumbnail bounded to the cell (`cacheWidth` → bounded memory,
/// Principle II). A video on disk shows a generated first-frame thumbnail
/// (#013, FR-012/013) lazily resolved + disk-cached; anything missing /
/// unreadable / not yet generated falls back to a category icon. Imports no
/// features.
class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    required this.category,
    this.localPath,
    this.cachePx = 240,
    super.key,
  });

  final MediaCategory category;
  final String? localPath;

  /// Decode width cap for the thumbnail bitmap (keeps a grid bounded).
  final int cachePx;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final raw = localPath;
    // Heal a stale iOS container path (rebuilds change the data-container UUID).
    final path = (raw == null || raw.isEmpty)
        ? null
        : ReceivedFilePath.resolve(raw);
    final onDisk = path != null && File(path).existsSync();

    if (category == MediaCategory.photos && onDisk) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        errorBuilder: (_, _, _) => _IconFill(category: category, color: c),
      );
    }
    if (category == MediaCategory.videos && onDisk) {
      return _VideoThumbnail(
        videoPath: path,
        cachePx: cachePx,
        fallback: _IconFill(category: category, color: c),
      );
    }
    return _IconFill(category: category, color: c);
  }
}

/// Lazily resolves + renders a video's first-frame thumbnail, decoding it at
/// most once per widget life; falls back to [fallback] (the play-glyph icon)
/// while loading or when generation is not possible (#013, FR-013).
class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({
    required this.videoPath,
    required this.cachePx,
    required this.fallback,
  });

  final String videoPath;
  final int cachePx;
  final Widget fallback;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  String? _thumbPath;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
  }

  Future<void> _resolve() async {
    final result = await getIt<VideoThumbnailService>().thumbnailPath(
      widget.videoPath,
    );
    if (!mounted) return;
    result.fold((path) {
      if (path != null) setState(() => _thumbPath = path);
    }, (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final path = _thumbPath;
    if (path == null) return widget.fallback;
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      cacheWidth: widget.cachePx,
      errorBuilder: (_, _, _) => widget.fallback,
    );
  }
}

class _IconFill extends StatelessWidget {
  const _IconFill({required this.category, required this.color});

  final MediaCategory category;
  final AppColors color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      MediaCategory.photos => LucideIcons.image,
      MediaCategory.videos => LucideIcons.video,
      MediaCategory.files => LucideIcons.file,
    };
    return ColoredBox(
      color: color.surfaceSunken,
      child: Center(child: Icon(icon, size: 26, color: color.textMuted)),
    );
  }
}
