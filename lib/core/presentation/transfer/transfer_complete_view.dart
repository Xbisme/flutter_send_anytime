import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Screen 06 (Hoàn tất) — the completion summary, shared by Send (#004) and
/// Receive (#005). Sender: a celebratory summary + Done / Send-more. Receiver: a
/// summary, the received-file list with per-file Open, a Share-all action, and a
/// **partial** variant (FR-013a) when only some files arrived.
class TransferCompleteView extends StatelessWidget {
  const TransferCompleteView({
    required this.view,
    required this.onDone,
    this.onSendAgain,
    this.onOpen,
    this.onShare,
    super.key,
  });

  final TransferView view;

  /// Return to Home.
  final VoidCallback onDone;

  /// Sender only: start a fresh send.
  final VoidCallback? onSendAgain;

  /// Receiver only: open one received file.
  final void Function(String path)? onOpen;

  /// Receiver only: hand all received files to the share sheet.
  final void Function(List<String> paths)? onShare;

  @override
  Widget build(BuildContext context) {
    final receiver = view.role == TransferRole.receiver;
    return receiver ? _ReceiverComplete(this) : _SenderComplete(this);
  }
}

class _SenderComplete extends StatelessWidget {
  const _SenderComplete(this.parent);

  final TransferCompleteView parent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final view = parent.view;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          const Spacer(),
          const _CheckBadge(),
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
                  onPressed: parent.onDone,
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: PrimaryButton(
                  label: l10n.sendAgain,
                  icon: LucideIcons.send,
                  onPressed: parent.onSendAgain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiverComplete extends StatelessWidget {
  const _ReceiverComplete(this.parent);

  final TransferCompleteView parent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final view = parent.view;
    final files = view.completedItems;
    final isPartial = view.isPartial;
    final title = isPartial
        ? l10n.receivePartialTitle
        : l10n.receiveCompleteTitle;
    final detail = isPartial
        ? l10n.receivePartialDetail(
            view.completedCount,
            view.fileCount,
            Formatters.bytes(_sum(files)),
          )
        : l10n.receiveCompleteDetail(
            view.fileCount,
            Formatters.bytes(view.bytesTotal),
            l10n.receivePeerSender,
            Formatters.clock(view.elapsed),
          );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x6),
          Center(child: _CheckBadge(partial: isPartial)),
          const SizedBox(height: AppSpacing.x5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x5),
          Expanded(
            child: ListView.separated(
              itemCount: files.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x2),
              itemBuilder: (context, i) {
                final f = files[i];
                return FileRow(
                  name: f.name,
                  ext: _ext(f.name),
                  meta: Formatters.bytes(f.size),
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.externalLink, size: 18),
                    tooltip: l10n.receiveOpen,
                    onPressed: f.finalPath == null
                        ? null
                        : () => parent.onOpen?.call(f.finalPath!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: l10n.receiveShare,
                  icon: LucideIcons.share2,
                  onPressed: files.isEmpty
                      ? null
                      : () => parent.onShare?.call(
                          [
                            for (final f in files) f.finalPath,
                          ].whereType<String>().toList(),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: PrimaryButton(
                  label: l10n.receiveDone,
                  onPressed: parent.onDone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _sum(List<FileTransferItem> items) => items.fold(0, (a, b) => a + b.size);
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge({this.partial = false});

  final bool partial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientBrand,
        boxShadow: AppShadow.accentGlow,
      ),
      child: Icon(
        partial ? LucideIcons.circleAlert : LucideIcons.check,
        size: 48,
        color: AppColors.onAccentDark,
      ),
    );
  }
}

String _ext(String name) {
  final dot = name.lastIndexOf('.');
  return dot > 0 && dot < name.length - 1 ? name.substring(dot + 1) : '';
}
