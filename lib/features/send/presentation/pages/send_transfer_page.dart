import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/transfer/progress_bar.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/send/domain/models/send_transfer_view.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';
import 'package:safe_send/features/send/presentation/send_failure_l10n.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';

/// Screens 05 (Đang truyền) + 06 (Hoàn tất): one route driven by the transfer
/// state-machine stream. Renders progress while sending, a completion summary
/// on success, and a typed, retryable failure otherwise (#004).
class SendTransferPage extends StatelessWidget {
  const SendTransferPage({required this.args, super.key});

  final SendProgressArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SendTransferCubit>(
      create: (_) {
        final cubit = getIt<SendTransferCubit>();
        unawaited(cubit.start(args.sources, args.transport));
        return cubit;
      },
      child: const _SendTransferView(),
    );
  }
}

class _SendTransferView extends StatelessWidget {
  const _SendTransferView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SendTransferCubit, AppState<SendTransferView>>(
          listenWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType ||
              (curr is AppLoaded<SendTransferView> &&
                  prev is AppLoaded<SendTransferView> &&
                  prev.data.phase != curr.data.phase),
          listener: (context, state) {
            if (state is AppError<SendTransferView>) {
              unawaited(HapticFeedback.heavyImpact());
            } else if (state is AppLoaded<SendTransferView>) {
              final phase = state.data.phase;
              if (phase == TransferPhase.done) {
                unawaited(HapticFeedback.mediumImpact());
              } else if (phase == TransferPhase.cancelled) {
                context.go(AppRoutes.home);
              }
            }
          },
          builder: (context, state) {
            return switch (state) {
              AppError<SendTransferView>(:final failure) => _FailureView(
                failure: failure,
              ),
              AppLoaded<SendTransferView>(:final data) when data.isDone =>
                _CompleteView(view: data),
              AppLoaded<SendTransferView>(:final data) => _ProgressView(
                view: data,
              ),
              _ => const _ProgressView(view: null),
            };
          },
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- progress ---

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.view});

  final SendTransferView? view;

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.sendCancelConfirmTitle),
        content: Text(l10n.sendCancelConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.sendCancelConfirmKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.sendCancel),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await context.read<SendTransferCubit>().cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final v = view;
    final percent = ((v?.overallProgress ?? 0) * 100).round();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x4),
          _Badge(label: l10n.sendProgressBadge, color: c.accent),
          const SizedBox(height: AppSpacing.x6),
          const _PeerRow(),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.sendProgressTo(l10n.sendPeerReceiver),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            '$percent%',
            textAlign: TextAlign.center,
            semanticsLabel: '${l10n.sendProgressBadge.toLowerCase()} $percent%',
            style: AppTypography.mono(size: 64, color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.x4),
          ProgressBar(value: v?.overallProgress ?? 0),
          const SizedBox(height: AppSpacing.x3),
          _SpeedRow(view: v),
          const SizedBox(height: AppSpacing.x6),
          if (v != null && v.currentFileName != null) _CurrentFileCard(view: v),
          const Spacer(),
          DangerButton(
            label: l10n.sendCancel,
            icon: LucideIcons.x,
            onPressed: () => _confirmCancel(context),
          ),
        ],
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _Avatar(gradient: AppColors.gradientBrand),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
          child: Icon(LucideIcons.chevronsRight, color: c.textMuted),
        ),
        const _Avatar(gradient: AppColors.gradientBrandVivid),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.gradient});

  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
      child: const Icon(
        LucideIcons.smartphone,
        size: 24,
        color: AppColors.onAccentDark,
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  const _SpeedRow({required this.view});

  final SendTransferView? view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final v = view;
    final style = AppTypography.mono(size: 13, color: c.textSecondary);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(LucideIcons.gauge, size: 15, color: c.textMuted),
            const SizedBox(width: AppSpacing.x2),
            Text(Formatters.speed(v?.speedBytesPerSec ?? 0), style: style),
          ],
        ),
        if (v?.etaSeconds != null)
          Text(
            l10n.sendProgressRemaining(
              Formatters.clock(Duration(seconds: v!.etaSeconds!)),
            ),
            style: style,
          ),
      ],
    );
  }
}

class _CurrentFileCard extends StatelessWidget {
  const _CurrentFileCard({required this.view});

  final SendTransferView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x3),
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: AppRadii.cardRadius,
        boxShadow: isDark ? AppShadow.softDark : AppShadow.softLight,
      ),
      child: Row(
        children: [
          FileChip(ext: _ext(view.currentFileName!)),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.currentFileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.sendProgressFilePosition(
                    (view.currentIndex ?? 0) + 1,
                    view.fileCount,
                  ),
                  style: AppTypography.mono(
                    size: 11,
                    color: c.textMuted,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
          const TransferSpinner(),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- complete ---

class _CompleteView extends StatelessWidget {
  const _CompleteView({required this.view});

  final SendTransferView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.gradientBrand,
              boxShadow: AppShadow.accentGlow,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 48,
              color: AppColors.onAccentDark,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            l10n.sendCompleteTitle,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.sendCompleteDetail(
              view.fileCount,
              Formatters.bytes(view.bytesTotal),
              l10n.sendPeerReceiver,
              Formatters.clock(view.elapsed),
            ),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.sendDone,
                  onPressed: () => context.go(AppRoutes.home),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: PrimaryButton(
                  label: l10n.sendAgain,
                  icon: LucideIcons.send,
                  onPressed: () => context.go(AppRoutes.send),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- failure ---

class _FailureView extends StatelessWidget {
  const _FailureView({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 44,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.sendErrorTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            failure.sendMessage(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: l10n.sendRetry,
            icon: LucideIcons.refreshCw,
            // Retry preserves the selection: pop back to the selection screen.
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.x3),
          SecondaryButton(
            label: l10n.commonBack,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x1,
        ),
        decoration: BoxDecoration(
          color: c.accentSubtle,
          borderRadius: AppRadii.pillRadius,
        ),
        child: Text(
          label,
          style: AppTypography.mono(size: 12, color: color, tracking: 1),
        ),
      ),
    );
  }
}

String _ext(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
}
