import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Section header for a day group in the History list (#006, FR-010). Shows
/// "Hôm nay"/"Hôm qua" for the two most recent local days, else a formatted
/// date.
class HistoryDayHeader extends StatelessWidget {
  const HistoryDayHeader({required this.day, super.key});

  /// Local-day bucket (midnight).
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final String label;
    if (day == today) {
      label = l10n.historyToday;
    } else if (day == yesterday) {
      label = l10n.historyYesterday;
    } else {
      label = DateFormat.yMMMMd(locale).format(day);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x1,
        AppSpacing.x4,
        AppSpacing.x1,
        AppSpacing.x2,
      ),
      child: Semantics(
        header: true,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: c.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
