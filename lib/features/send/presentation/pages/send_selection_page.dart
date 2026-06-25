import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/send/domain/models/send_selection.dart';
import 'package:safe_send/features/send/presentation/cubit/send_selection_cubit.dart';
import 'package:safe_send/features/send/presentation/send_failure_l10n.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';

/// Screen 02 — Gửi file: pick any-type files, review per-file + total size,
/// remove mistakes, then continue to pairing. Full-screen, nav-less (#004).
class SendSelectionPage extends StatelessWidget {
  const SendSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SendSelectionCubit>(
      create: (_) => getIt<SendSelectionCubit>(),
      child: const _SendSelectionView(),
    );
  }
}

class _SendSelectionView extends StatelessWidget {
  const _SendSelectionView();

  Future<void> _continue(BuildContext context, SendSelection selection) async {
    final result = await context.push<ConnectResult>(
      AppRoutes.connect,
      extra: const ConnectRequest(role: TransferRole.sender),
    );
    if (result == null || !context.mounted) return;
    await context.push(
      AppRoutes.sendProgress,
      extra: SendProgressArgs(
        sources: selection.toSources(),
        transport: result.transport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SendSelectionCubit, AppState<SendSelection>>(
          listener: (context, state) {
            if (state is AppError<SendSelection>) {
              AppToast.show(
                context,
                state.failure.sendMessage(l10n),
                type: AppToastType.error,
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<SendSelectionCubit>();
            final selection = cubit.selection;
            return Column(
              children: [
                FlowAppBar(
                  title: l10n.sendTitle,
                  leadingIcon: LucideIcons.x,
                  onLeading: () => context.pop(),
                  leadingSemanticLabel: l10n.commonBack,
                ),
                Expanded(
                  child: selection.isEmpty
                      ? _EmptyTray()
                      : _SelectedTray(
                          selection: selection,
                          onRemove: cubit.removeAt,
                        ),
                ),
                _Footer(
                  canContinue: !selection.isEmpty,
                  onAdd: cubit.addFiles,
                  onContinue: () => _continue(context, selection),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyTray extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CenteredEmpty(
      icon: LucideIcons.filePlus,
      title: l10n.sendEmptyTitle,
      body: l10n.sendEmptyBody,
    );
  }
}

class _SelectedTray extends StatelessWidget {
  const _SelectedTray({required this.selection, required this.onRemove});

  final SendSelection selection;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        0,
        AppSpacing.x5,
        AppSpacing.x5,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            color: c.accentSubtle,
            borderRadius: AppRadii.cardRadius,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.checkCheck, size: 20, color: c.accent),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Text(
                  l10n.sendSelectedSummary(
                    selection.count,
                    Formatters.bytes(selection.totalBytes),
                  ),
                  style: AppTypography.mono(size: 14, color: c.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        for (var i = 0; i < selection.files.length; i++) ...[
          FileRow(
            name: selection.files[i].name,
            ext: _ext(selection.files[i].name),
            meta: Formatters.bytes(selection.files[i].size),
            trailing: IconButton(
              icon: Icon(LucideIcons.x, size: 18, color: c.textMuted),
              tooltip: l10n.sendRemove,
              onPressed: () => onRemove(i),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canContinue,
    required this.onAdd,
    required this.onContinue,
  });

  final bool canContinue;
  final VoidCallback onAdd;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: l10n.sendAdd,
              icon: LucideIcons.plus,
              onPressed: onAdd,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: PrimaryButton(
              label: l10n.sendContinue,
              icon: LucideIcons.arrowRight,
              onPressed: canContinue ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredEmpty extends StatelessWidget {
  const _CenteredEmpty({
    required this.icon,
    required this.title,
    required this.body,
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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

String _ext(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
}
