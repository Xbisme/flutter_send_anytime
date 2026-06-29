import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/utils/file_category.dart';

/// Fills a media grid cell (#012). For a photo whose file is available locally
/// it shows a real decoded thumbnail bounded to the cell (`cacheWidth` →
/// bounded memory, Principle II); otherwise — a video, a sent/missing/unreadable
/// file, or a decode error — it falls back to a category icon on a token
/// background (FR-006a). Imports no features.
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
    final path = localPath;
    if (category == MediaCategory.photos &&
        path != null &&
        path.isNotEmpty &&
        File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        errorBuilder: (_, _, _) => _IconFill(category: category, color: c),
      );
    }
    return _IconFill(category: category, color: c);
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
