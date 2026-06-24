import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Pill segmented control; active segment is a raised surface with accent text.
///
/// Reserved component — first used by #003 (Connect hub). Built per FR-017.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? c.surfaceCard : null,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: i == selectedIndex
                        ? (isDark ? AppShadow.softDark : AppShadow.softLight)
                        : null,
                  ),
                  child: Text(
                    segments[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex ? c.accent : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
