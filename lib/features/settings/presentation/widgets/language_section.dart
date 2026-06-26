import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/presentation/inputs/segmented_tabs.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/widgets/settings_section_card.dart';

/// Language section (#010, US3, FR-012): Tiếng Việt / English / Theo hệ thống.
/// Applies app-wide immediately; `system` follows the OS locale with a VI
/// fallback.
class LanguageSection extends StatelessWidget {
  const LanguageSection({required this.value, super.key});

  final LanguagePreference value;

  static const List<LanguagePreference> _order = [
    LanguagePreference.vietnamese,
    LanguagePreference.english,
    LanguagePreference.system,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSectionCard(
      header: l10n.settingsSectionLanguage,
      child: SegmentedTabs(
        segments: [
          l10n.settingsLanguageVi,
          l10n.settingsLanguageEn,
          l10n.settingsLanguageSystem,
        ],
        selectedIndex: _order.indexOf(value),
        onChanged: (i) => context.read<SettingsCubit>().setLanguage(_order[i]),
      ),
    );
  }
}
