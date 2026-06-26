import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/settings/device_profile.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';

/// Device-profile card (#010, US1): gradient letter avatar + the editable name
/// shown to peers + a pencil that opens the rename dialog (FR-001/002/003).
class DeviceProfileCard extends StatelessWidget {
  const DeviceProfileCard({required this.profile, super.key});

  final DeviceProfile profile;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadow = isDark ? AppShadow.softDark : AppShadow.softLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: AppRadii.cardLgRadius,
        boxShadow: cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppColors.gradientBrandVivid,
              shape: BoxShape.circle,
            ),
            child: Text(
              profile.initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 21,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x4 - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.settingsProfileSub,
                  style: AppTypography.mono(
                    size: 12,
                    color: c.textSecondary,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.pencil, size: 18, color: c.textMuted),
            tooltip: l10n.settingsProfileEditTitle,
            onPressed: () => _showEditDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          _RenameDialog(initial: profile.name, cubit: context.read()),
    );
  }
}

/// The device-rename dialog. A [StatefulWidget] so it owns its
/// [TextEditingController] and disposes it safely after the close animation —
/// disposing a controller created by the caller right after `showDialog`
/// returns crashes the dialog's exit transition.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial, required this.cubit});

  final String initial;
  final SettingsCubit cubit;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final result = await widget.cubit.setDeviceName(_controller.text);
    if (!mounted) return;
    result.fold(
      (_) => navigator.pop(),
      (_) => AppToast.show(
        context,
        l10n.settingsProfileNameError,
        type: AppToastType.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A plain Material AlertDialog (NOT .adaptive): the adaptive variant
    // renders a CupertinoAlertDialog on iOS, which provides no Material ancestor
    // and crashes the TextField ("No Material widget found").
    return AlertDialog(
      title: Text(l10n.settingsProfileEditTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        decoration: InputDecoration(hintText: l10n.settingsProfileNameHint),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.commonSave)),
      ],
    );
  }
}
