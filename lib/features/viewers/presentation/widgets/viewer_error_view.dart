import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Shared error state for any viewer that cannot render its file (corrupt /
/// unreadable / unsupported decode — FR-015). Offers the OS open/share
/// handoff so the user is never dead-ended. [dark] for full-bleed viewers.
class ViewerErrorView extends StatelessWidget {
  const ViewerErrorView({
    required this.message,
    required this.path,
    this.dark = false,
    super.key,
  });

  final String message;
  final String path;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = dark ? Colors.white : c.textPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.fileWarning, size: 40, color: fg),
            const SizedBox(height: AppSpacing.x3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: fg),
            ),
            const SizedBox(height: AppSpacing.x4),
            SecondaryButton(
              label: context.l10n.viewerOpenExternally,
              onPressed: () => getIt<ReceivedFilesService>().open(path),
            ),
          ],
        ),
      ),
    );
  }
}
