import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/presentation/inputs/toggle_row.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Settings tab placeholder (#001). Toggles are visual-only; real preference
/// logic + device profile editing land in #010.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadow = isDark ? AppShadow.softDark : AppShadow.softLight;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x2,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.x4),
            // Device profile card.
            Container(
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
                    child: const Text(
                      'A',
                      style: TextStyle(
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
                          "An's iPhone 15",
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
                  Icon(LucideIcons.pencil, size: 18, color: c.textMuted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            // Toggle group (static).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: AppRadii.cardLgRadius,
                boxShadow: cardShadow,
              ),
              child: Column(
                children: [
                  ToggleRow(
                    icon: LucideIcons.download,
                    label: l10n.settingsAutoReceive,
                    subtitle: l10n.settingsAutoReceiveSub,
                    value: true,
                  ),
                  ToggleRow(
                    icon: LucideIcons.image,
                    label: l10n.settingsSaveToLibrary,
                    subtitle: l10n.settingsSaveToLibrarySub,
                    value: true,
                  ),
                  ToggleRow(
                    icon: LucideIcons.bell,
                    label: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsSub,
                    value: false,
                  ),
                  ToggleRow(
                    icon: LucideIcons.moon,
                    label: l10n.settingsDarkMode,
                    subtitle: l10n.settingsDarkModeSub,
                    value: isDark,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            Center(
              child: Text(
                l10n.settingsVersion('1.0.0'),
                style: AppTypography.mono(
                  size: 11,
                  color: c.textMuted,
                  weight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
