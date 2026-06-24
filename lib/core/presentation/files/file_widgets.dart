import 'package:flutter/material.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';

/// Rounded file-extension badge, colored by file type.
class FileChip extends StatelessWidget {
  const FileChip({required this.ext, this.size = 42, super.key});

  final String ext;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FileTypeColors.background(ext),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        ext.toUpperCase(),
        style: AppTypography.mono(
          size: 11,
          color: FileTypeColors.foreground(ext),
        ),
      ),
    );
  }
}

/// Card row: file chip + name (ellipsis) + mono meta + optional trailing slot.
class FileRow extends StatelessWidget {
  const FileRow({
    required this.name,
    required this.ext,
    this.meta,
    this.trailing,
    super.key,
  });

  final String name;
  final String ext;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: AppRadii.cardRadius,
        boxShadow: isDark ? AppShadow.softDark : AppShadow.softLight,
      ),
      child: Row(
        children: [
          FileChip(ext: ext),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (meta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.mono(
                      size: 11,
                      color: c.textMuted,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.x2),
            trailing!,
          ],
        ],
      ),
    );
  }
}
