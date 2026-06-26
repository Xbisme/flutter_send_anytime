import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/inputs/toggle_row.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/widgets/about_section.dart';
import 'package:safe_send/features/settings/presentation/widgets/advanced_section.dart';
import 'package:safe_send/features/settings/presentation/widgets/device_profile_card.dart';
import 'package:safe_send/features/settings/presentation/widgets/language_section.dart';
import 'package:safe_send/features/settings/presentation/widgets/theme_section.dart';

/// Settings tab (#010). Reads the app-wide [SettingsCubit] (single source of
/// truth, FR-020) and renders the device profile, the incoming-file toggle
/// group, and (per later stories) appearance/language, advanced, and about
/// sections.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, AppState<AppSettings>>(
      builder: (context, state) {
        if (state is! AppLoaded<AppSettings>) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        return _SettingsView(settings: state.data);
      },
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardShadow = isDark ? AppShadow.softDark : AppShadow.softLight;
    final cubit = context.read<SettingsCubit>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x2,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.x4),
            DeviceProfileCard(profile: settings.profile),
            const SizedBox(height: AppSpacing.x4),
            // Incoming-file behavior toggles (US2 adds permission gating).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: AppRadii.cardLgRadius,
                boxShadow: cardShadow,
              ),
              child: Column(
                children: [
                  ToggleRow(
                    icon: LucideIcons.download,
                    label: l10n.settingsAutoReceive,
                    subtitle: l10n.settingsAutoReceiveSub,
                    value: settings.autoReceive,
                    onChanged: (v) => cubit.setAutoReceive(value: v),
                  ),
                  ToggleRow(
                    icon: LucideIcons.image,
                    label: l10n.settingsSaveToLibrary,
                    subtitle: l10n.settingsSaveToLibrarySub,
                    value: settings.saveToLibrary,
                    onChanged: (v) => _gatedToggle(
                      context,
                      () => cubit.setSaveToLibrary(value: v),
                    ),
                  ),
                  ToggleRow(
                    icon: LucideIcons.bell,
                    label: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsSub,
                    value: settings.notifications,
                    onChanged: (v) => _gatedToggle(
                      context,
                      () => cubit.setNotifications(value: v),
                    ),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            ThemeSection(value: settings.theme),
            const SizedBox(height: AppSpacing.x4),
            LanguageSection(value: settings.language),
            const SizedBox(height: AppSpacing.x4),
            AdvancedSection(endpoint: settings.signalingOverride),
            const SizedBox(height: AppSpacing.x4),
            const AboutSection(),
          ],
        ),
      ),
    );
  }

  /// Run a permission-gated toggle setter; on denial the toggle stays off and a
  /// blocked toast is shown (FR-010 / SC-005).
  Future<void> _gatedToggle(
    BuildContext context,
    Future<Result<void>> Function() set,
  ) async {
    final l10n = context.l10n;
    final result = await set();
    if (!context.mounted) return;
    result.fold(
      (_) {},
      (_) => AppToast.show(
        context,
        l10n.settingsPermissionBlocked,
        type: AppToastType.error,
      ),
    );
  }
}
