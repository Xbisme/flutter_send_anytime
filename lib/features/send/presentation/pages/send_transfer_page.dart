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
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/transfer/transfer_complete_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_view.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/send/presentation/cubit/send_transfer_cubit.dart';
import 'package:safe_send/features/send/presentation/send_failure_l10n.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';

/// Screens 05 (Đang truyền) + 06 (Hoàn tất): one route driven by the transfer
/// state-machine stream. Renders the shared progress view while sending, the
/// shared completion summary on success, and a typed, retryable failure
/// otherwise (#004; progress/complete lifted to `core/presentation/transfer`).
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
        child: BlocConsumer<SendTransferCubit, AppState<TransferView>>(
          listenWhen: (prev, curr) =>
              prev.runtimeType != curr.runtimeType ||
              (curr is AppLoaded<TransferView> &&
                  prev is AppLoaded<TransferView> &&
                  prev.data.phase != curr.data.phase),
          listener: (context, state) {
            if (state is AppError<TransferView>) {
              unawaited(HapticFeedback.heavyImpact());
            } else if (state is AppLoaded<TransferView>) {
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
              AppError<TransferView>(:final failure) => _FailureView(
                failure: failure,
              ),
              AppLoaded<TransferView>(:final data) when data.isDone =>
                TransferCompleteView(
                  view: data,
                  onDone: () => context.go(AppRoutes.home),
                  onSendAgain: () => context.go(AppRoutes.send),
                ),
              AppLoaded<TransferView>(:final data) => TransferProgressView(
                view: data,
                onCancel: () => context.read<SendTransferCubit>().cancel(),
              ),
              _ => TransferProgressView(
                view: null,
                onCancel: () => context.read<SendTransferCubit>().cancel(),
              ),
            };
          },
        ),
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
