import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';

/// Square statistic tile: icon chip + mono count + label.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.count,
    required this.label,
    required this.tint,
    super.key,
  });

  final IconData icon;
  final String count;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.x4 - 1,
        horizontal: AppSpacing.x3 - 2,
      ),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: AppRadii.cardLgRadius,
        boxShadow: isDark ? AppShadow.softDark : AppShadow.softLight,
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
            child: Icon(icon, size: 19, color: tint),
          ),
          const SizedBox(height: AppSpacing.x2 + 1),
          Text(
            count,
            style: AppTypography.mono(size: 19, color: c.textPrimary),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
