import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/presentation/inputs/segmented_tabs.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/widgets/settings_section_card.dart';

/// Appearance section (#010, US3, FR-011): a **3-way** theme picker — Sáng /
/// Tối / Theo hệ thống (NOT a binary dark toggle). The palette is fixed; this
/// only changes the mode.
class ThemeSection extends StatelessWidget {
  const ThemeSection({required this.value, super.key});

  final ThemePreference value;

  static const List<ThemePreference> _order = [
    ThemePreference.light,
    ThemePreference.dark,
    ThemePreference.system,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSectionCard(
      header: l10n.settingsSectionAppearance,
      child: SegmentedTabs(
        segments: [
          l10n.settingsThemeLight,
          l10n.settingsThemeDark,
          l10n.settingsThemeSystem,
        ],
        selectedIndex: _order.indexOf(value),
        onChanged: (i) => context.read<SettingsCubit>().setTheme(_order[i]),
      ),
    );
  }
}
