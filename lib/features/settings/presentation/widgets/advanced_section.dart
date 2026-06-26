import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/widgets/settings_section_card.dart';

/// Advanced section (#010, US4): override the signaling endpoint + run a
/// reachability diagnostic. Saving validates the scheme (`wss` any flavor, `ws`
/// dev-only, FR-014); clearing restores the per-flavor default.
class AdvancedSection extends StatefulWidget {
  const AdvancedSection({required this.endpoint, super.key});

  /// The current override (null when using the flavor default).
  final Uri? endpoint;

  @override
  State<AdvancedSection> createState() => _AdvancedSectionState();
}

class _AdvancedSectionState extends State<AdvancedSection> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.endpoint?.toString() ?? '',
  );
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cubit = context.read<SettingsCubit>();
    final l10n = context.l10n;
    final text = _controller.text.trim();
    final result = await cubit.setSignalingOverride(
      text.isEmpty ? null : Uri.tryParse(text) ?? Uri(path: text),
    );
    if (!mounted) return;
    result.fold(
      (_) {},
      (_) => AppToast.show(
        context,
        l10n.settingsEndpointInvalid,
        type: AppToastType.error,
      ),
    );
  }

  Future<void> _clear() async {
    final cubit = context.read<SettingsCubit>();
    await cubit.setSignalingOverride(null);
    if (mounted) _controller.clear();
  }

  Future<void> _diagnose() async {
    final cubit = context.read<SettingsCubit>();
    final l10n = context.l10n;
    setState(() => _busy = true);
    final result = await cubit.runDiagnostic();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      (_) => AppToast.show(
        context,
        l10n.settingsDiagnosticReachable,
        type: AppToastType.success,
      ),
      (_) => AppToast.show(
        context,
        l10n.settingsDiagnosticUnreachable,
        type: AppToastType.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SettingsSectionCard(
      header: l10n.settingsSectionAdvanced,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(hintText: l10n.settingsEndpointHint),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.x3),
          PrimaryButton(
            label: l10n.settingsDiagnosticRun,
            onPressed: _busy ? null : _diagnose,
          ),
          const SizedBox(height: AppSpacing.x2),
          SecondaryButton(label: l10n.commonSave, onPressed: _save),
          const SizedBox(height: AppSpacing.x2),
          SecondaryButton(
            label: l10n.settingsEndpointClear,
            onPressed: _clear,
          ),
        ],
      ),
    );
  }
}
