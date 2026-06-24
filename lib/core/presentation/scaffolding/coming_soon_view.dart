import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Branded "coming soon" placeholder body for not-yet-built flows (#001).
class ComingSoonView extends StatelessWidget {
  const ComingSoonView({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientBrand,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.x5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
