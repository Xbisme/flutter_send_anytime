import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// A titled card wrapper for a Settings section (#010), matching the profile/
/// toggle cards' surface + radius + soft shadow.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    required this.header,
    required this.child,
    super.key,
  });

  final String header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadow = isDark ? AppShadow.softDark : AppShadow.softLight;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: AppRadii.cardLgRadius,
        boxShadow: cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(header, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.x3),
          child,
        ],
      ),
    );
  }
}
