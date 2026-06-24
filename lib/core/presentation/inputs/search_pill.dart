import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Presentational (inert) search field pill. #001 does not perform search;
/// this is a no-op affordance (FR-009).
class SearchPill extends StatelessWidget {
  const SearchPill({required this.hintText, super.key});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: hintText,
      readOnly: true,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: AppRadii.pillRadius,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.search, size: 18, color: c.textMuted),
            const SizedBox(width: AppSpacing.x2 + 2),
            Expanded(
              child: Text(
                hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
