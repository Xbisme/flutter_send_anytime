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
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/transfer/transfer_complete_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_view.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/receive/presentation/cubit/receive_transfer_cubit.dart';
import 'package:safe_send/features/receive/presentation/receive_failure_l10n.dart';
import 'package:safe_send/features/receive/presentation/widgets/incoming_transfer_dialog.dart';

/// Screens 05 (Đang truyền) + 06 (Hoàn tất) for the receiver (#005). Drives the
/// shared progress/complete views off the engine snapshot stream; shows the
/// accept/reject prompt when the manifest arrives; routes Reject → Home and a
/// recoverable failure → a retry that restarts the receive flow (FR-009/023).
class ReceiveTransferPage extends StatelessWidget {
  const ReceiveTransferPage({required this.transport, super.key});

  final DataTransport transport;

  @override
  Widget build(BuildContext context) {
    final senderLabel = context.l10n.receivePeerSender;
    return BlocProvider<ReceiveTransferCubit>(
      create: (_) {
        final cubit = getIt<ReceiveTransferCubit>();
        unawaited(cubit.start(transport, senderLabel: senderLabel));
        return cubit;
      },
      child: const _ReceiveTransferView(),
    );
  }
}

class _ReceiveTransferView extends StatefulWidget {
  const _ReceiveTransferView();

  @override
  State<_ReceiveTransferView> createState() => _ReceiveTransferViewState();
}

class _ReceiveTransferViewState extends State<_ReceiveTransferView> {
  bool _promptShown = false;

  Future<void> _onState(
    BuildContext context,
    AppState<TransferView> state,
  ) async {
    final cubit = context.read<ReceiveTransferCubit>();
    if (state is AppLoaded<TransferView> &&
        state.data.awaitingDecision &&
        state.data.incomingOffer != null &&
        !_promptShown) {
      _promptShown = true;
      final accepted = await showIncomingTransferDialog(
        context,
        state.data.incomingOffer!,
      );
      if (!context.mounted) return;
      if (accepted ?? false) {
        cubit.accept();
      } else {
        cubit.reject();
      }
    } else if (state is AppLoaded<TransferView> && state.data.isDone) {
      unawaited(HapticFeedback.mediumImpact());
    } else if (state is AppError<TransferView>) {
      unawaited(HapticFeedback.heavyImpact());
      // A user-initiated reject ends the flow at Home (FR-009).
      if (cubit.rejectedByUser) context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ReceiveTransferCubit, AppState<TransferView>>(
          listener: _onState,
          builder: (context, state) {
            final cancel = context.read<ReceiveTransferCubit>().cancel;
            return switch (state) {
              AppError<TransferView>(:final failure) => _FailureView(
                failure: failure,
              ),
              // Terminal full or partial (FR-013a) → the completion summary.
              AppLoaded<TransferView>(:final data)
                  when data.isDone || data.isPartial =>
                TransferCompleteView(
                  view: data,
                  onDone: () => context.go(AppRoutes.home),
                  onOpen: (path) => _open(context, path),
                  onShare: (paths) => _share(context, paths),
                ),
              AppLoaded<TransferView>(:final data) => TransferProgressView(
                view: data,
                onCancel: cancel,
              ),
              _ => TransferProgressView(view: null, onCancel: cancel),
            };
          },
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, String path) async {
    final l10n = context.l10n;
    final result = await context.read<ReceiveTransferCubit>().openFile(path);
    if (!context.mounted) return;
    result.fold(
      (_) {},
      (_) => AppToast.show(context, l10n.receiveOpenFailed, type: AppToastType.error),
    );
  }

  Future<void> _share(BuildContext context, List<String> paths) async {
    final l10n = context.l10n;
    final result = await context.read<ReceiveTransferCubit>().shareFiles(paths);
    if (!context.mounted) return;
    result.fold(
      (_) {},
      (_) => AppToast.show(context, l10n.receiveShareFailed, type: AppToastType.error),
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
          const Icon(LucideIcons.circleAlert, size: 44, color: AppColors.danger),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.receiveErrorTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            failure.receiveMessage(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: l10n.receiveRetry,
            icon: LucideIcons.refreshCw,
            // Retry restarts the receive flow (re-opens code entry, FR-023).
            onPressed: () => context.go(AppRoutes.receive),
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
