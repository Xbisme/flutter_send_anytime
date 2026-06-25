import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/inputs/segmented_tabs.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Search + direction + date filter bar for the History tab (#006, US4).
/// Stateless over the cubit: it reports changes through callbacks and reflects
/// the current [direction]/[hasDateFilter] selection.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    required this.controller,
    required this.direction,
    required this.hasDateFilter,
    required this.onQueryChanged,
    required this.onDirectionChanged,
    required this.onPickDate,
    required this.onClearDate,
    super.key,
  });

  final TextEditingController controller;
  final TransferDirection? direction;
  final bool hasDateFilter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<TransferDirection?> onDirectionChanged;
  final VoidCallback onPickDate;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final selectedIndex = switch (direction) {
      null => 0,
      TransferDirection.sent => 1,
      TransferDirection.received => 2,
    };

    return Column(
      children: [
        Container(
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
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l10n.historySearchHint,
                    hintStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: c.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        Row(
          children: [
            Expanded(
              child: SegmentedTabs(
                segments: [
                  l10n.historyFilterAll,
                  l10n.historyDirectionSent,
                  l10n.historyDirectionReceived,
                ],
                selectedIndex: selectedIndex,
                onChanged: (i) => onDirectionChanged(switch (i) {
                  1 => TransferDirection.sent,
                  2 => TransferDirection.received,
                  _ => null,
                }),
              ),
            ),
            const SizedBox(width: AppSpacing.x2),
            Semantics(
              button: true,
              selected: hasDateFilter,
              label: l10n.historyFilterDate,
              child: InkResponse(
                onTap: hasDateFilter ? onClearDate : onPickDate,
                radius: 26,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasDateFilter ? c.accentSubtle : c.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasDateFilter
                        ? LucideIcons.calendarOff
                        : LucideIcons.calendar,
                    size: 18,
                    color: hasDateFilter ? c.accent : c.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
