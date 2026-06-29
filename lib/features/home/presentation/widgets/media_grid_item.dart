import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/media/media_thumbnail.dart';
import 'package:safe_send/core/presentation/viewers/file_open_coordinator.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Tap a media item → its in-app viewer when the file is received + on disk +
/// a supported type (#013, FR-001); otherwise → its History detail page (the
/// #012/FR-007 behaviour, e.g. a sent item or a no-longer-present file).
void openMediaItem(BuildContext context, MediaItem item) {
  final isReceived = item.record.direction == TransferDirection.received;
  final request = FileOpenCoordinator.viewableRequestFor(
    name: item.name,
    path: item.localPath,
    mimeType: null,
    isReceived: isReceived,
  );
  if (request != null) {
    unawaited(context.push(AppRoutes.fileViewer, extra: request));
  } else {
    unawaited(context.push(AppRoutes.historyDetail, extra: item.record));
  }
}

/// Square photo cell: real thumbnail (or icon fallback) + name overlay (#012).
class MediaPhotoCell extends StatelessWidget {
  const MediaPhotoCell({required this.item, super.key});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.name}, ${item.sizeLabel}',
      child: GestureDetector(
        onTap: () => openMediaItem(context, item),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaThumbnail(
                category: item.category,
                localPath: item.localPath,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Color(0x80000000), Color(0x00000000)],
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.x2,
                right: AppSpacing.x2,
                bottom: AppSpacing.x1 + 3,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Video cell: token tile + play glyph + optional duration badge + name/size
/// (#012; no real frame — that is #013).
class MediaVideoCell extends StatelessWidget {
  const MediaVideoCell({required this.item, super.key});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final duration = item.durationLabel;
    return Semantics(
      button: true,
      label: '${item.name}, ${item.sizeLabel}',
      child: GestureDetector(
        onTap: () => openMediaItem(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MediaThumbnail(
                      category: item.category,
                      localPath: item.localPath,
                    ),
                    const Center(
                      child: Icon(
                        LucideIcons.play,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    if (duration != null)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            duration,
                            style: AppTypography.mono(
                              size: 10,
                              color: Colors.white,
                              weight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              item.sizeLabel,
              style: AppTypography.mono(
                size: 11,
                color: c.textMuted,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// File row (non-media): FileChip + name + size, tappable (#012).
class MediaFileRow extends StatelessWidget {
  const MediaFileRow({required this.item, super.key});
  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => openMediaItem(context, item),
        child: FileRow(name: item.name, ext: item.ext, meta: item.sizeLabel),
      ),
    );
  }
}
