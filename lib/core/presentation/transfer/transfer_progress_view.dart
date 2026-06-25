import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/transfer/progress_bar.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Screen 05 (Đang truyền) — the live transfer progress UI, shared by Send
/// (#004) and Receive (#005). Role-parameterized via [TransferView.role]: the
/// badge, peer line, and cancel copy switch between sender/receiver. Driven
/// entirely by the engine snapshot stream (Constitution VIII). [onCancel] runs
/// the actual cancel after the confirm dialog.
class TransferProgressView extends StatelessWidget {
  const TransferProgressView({
    required this.view,
    required this.onCancel,
    super.key,
  });

  /// The latest projection; null before the first snapshot.
  final TransferView? view;

  /// Performs the cancel once the user confirms.
  final Future<void> Function() onCancel;

  bool get _isReceiver => view?.role == TransferRole.receiver;

  Future<void> _confirmCancel(BuildContext context) async {
    final l10n = context.l10n;
    final receiver = _isReceiver;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          receiver
              ? l10n.receiveCancelConfirmTitle
              : l10n.sendCancelConfirmTitle,
        ),
        content: Text(
          receiver ? l10n.receiveCancelConfirmBody : l10n.sendCancelConfirmBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              receiver
                  ? l10n.receiveCancelConfirmKeep
                  : l10n.sendCancelConfirmKeep,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(receiver ? l10n.receiveCancel : l10n.sendCancel),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final v = view;
    final receiver = _isReceiver;
    final percent = ((v?.overallProgress ?? 0) * 100).round();
    final badge = receiver ? l10n.receiveProgressBadge : l10n.sendProgressBadge;
    final peerLine = receiver
        ? l10n.receiveProgressFrom(l10n.receivePeerSender)
        : l10n.sendProgressTo(l10n.sendPeerReceiver);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x4),
          _Badge(label: badge, color: c.accent),
          const SizedBox(height: AppSpacing.x6),
          const _PeerRow(),
          const SizedBox(height: AppSpacing.x3),
          Text(
            peerLine,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Spacer(),
          Text(
            '$percent%',
            textAlign: TextAlign.center,
            semanticsLabel: '${badge.toLowerCase()} $percent%',
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
            label: receiver ? l10n.receiveCancel : l10n.sendCancel,
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

  final TransferView? view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final v = view;
    final receiver = v?.role == TransferRole.receiver;
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
            receiver
                ? l10n.receiveProgressRemaining(
                    Formatters.clock(Duration(seconds: v!.etaSeconds!)),
                  )
                : l10n.sendProgressRemaining(
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

  final TransferView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final receiver = view.role == TransferRole.receiver;
    final position = receiver
        ? l10n.receiveProgressFilePosition(
            (view.currentIndex ?? 0) + 1,
            view.fileCount,
          )
        : l10n.sendProgressFilePosition(
            (view.currentIndex ?? 0) + 1,
            view.fileCount,
          );
    return FileRow(
      name: view.currentFileName!,
      ext: _ext(view.currentFileName!),
      meta: position,
      trailing: const TransferSpinner(),
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
