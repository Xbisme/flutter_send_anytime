import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/services/app_info_service.dart';
import 'package:safe_send/core/services/app_review_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/widgets/settings_section_card.dart';

/// About section (#010, US5): version + tagline, in-app how-it-works/privacy
/// nav rows, and the native rate action (FR-016/017/018).
class AboutSection extends StatelessWidget {
  const AboutSection({this.appInfo, this.review, super.key});

  /// Injectable for tests; defaults to the DI singletons.
  final AppInfoService? appInfo;
  final AppReviewService? review;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final info = appInfo ?? getIt<AppInfoService>();

    return SettingsSectionCard(
      header: l10n.settingsSectionAbout,
      child: Column(
        children: [
          _NavRow(
            icon: LucideIcons.shieldCheck,
            label: l10n.settingsHowItWorks,
            onTap: () => context.push(AppRoutes.settingsHowItWorks),
          ),
          _NavRow(
            icon: LucideIcons.fileText,
            label: l10n.settingsPrivacy,
            onTap: () => context.push(AppRoutes.settingsPrivacy),
          ),
          _NavRow(
            icon: LucideIcons.star,
            label: l10n.settingsRate,
            onTap: () => (review ?? getIt<AppReviewService>()).requestReview(),
            showDivider: false,
          ),
          const SizedBox(height: AppSpacing.x3),
          FutureBuilder<String>(
            future: info.version(),
            builder: (context, snapshot) => Text(
              l10n.settingsVersion(snapshot.data ?? '1.0.0'),
              style: AppTypography.mono(
                size: 11,
                color: c.textMuted,
                weight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: showDivider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderSubtle)),
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3 + 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: c.accent),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}
