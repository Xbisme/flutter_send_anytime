import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Shared top bar for every in-app viewer (#013, FR-011): a circular back
/// button, the file name, and a share/open-in action that reuses the existing
/// OS share sheet. [dark] tunes contrast for full-bleed image/video viewers.
class ViewerTopBar extends StatelessWidget {
  const ViewerTopBar({
    required this.title,
    required this.sharePath,
    this.dark = false,
    super.key,
  });

  final String title;

  /// The on-disk path shared by the share action.
  final String sharePath;
  final bool dark;

  Future<void> _share() => getIt<ReceivedFilesService>().share([sharePath]);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final fg = dark ? Colors.white : c.textPrimary;
    final chipBg = dark
        ? Colors.black.withValues(alpha: 0.35)
        : c.surfaceSunken;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x4,
          AppSpacing.x2,
          AppSpacing.x4,
          AppSpacing.x2,
        ),
        child: Row(
          children: [
            _CircleButton(
              icon: LucideIcons.arrowLeft,
              semanticLabel: l10n.viewerBack,
              fg: fg,
              bg: chipBg,
              onTap: () => context.pop(),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: fg),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            _CircleButton(
              icon: LucideIcons.share2,
              semanticLabel: l10n.viewerActionShare,
              fg: fg,
              bg: chipBg,
              onTap: _share,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.semanticLabel,
    required this.fg,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final Color fg;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: fg),
        ),
      ),
    );
  }
}
