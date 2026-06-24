import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Centered empty-state: icon + title + optional body + optional CTA.
class AppEmptyView extends StatelessWidget {
  const AppEmptyView({
    required this.icon,
    required this.title,
    this.body,
    this.cta,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? cta;

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
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: c.textMuted),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
              ),
            ],
            if (cta != null) ...[
              const SizedBox(height: AppSpacing.x5),
              cta!,
            ],
          ],
        ),
      ),
    );
  }
}
