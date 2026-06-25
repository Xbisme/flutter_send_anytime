import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// The incoming-transfer prompt (#005, US2) — the design's accept/reject dialog.
/// Shows the sender label + manifest summary (count/size/types) and returns
/// `true` (Nhận) / `false` (Từ chối) via `Navigator.pop`. Shown with
/// [showIncomingTransferDialog].
class IncomingTransferDialog extends StatelessWidget {
  const IncomingTransferDialog({required this.offer, super.key});

  final IncomingOffer offer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradientBrandVivid,
              ),
              child: const Icon(
                LucideIcons.download,
                size: 26,
                color: AppColors.onAccentDark,
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              l10n.receivePromptTitle(offer.senderLabel),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              l10n.receivePromptBody(
                offer.fileCount,
                Formatters.bytes(offer.totalBytes),
              ),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            if (offer.typeSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x1),
              Text(
                offer.typeSummary.join(' · '),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.x5),
            PrimaryButton(
              label: l10n.receiveAccept,
              icon: LucideIcons.check,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppSpacing.x2),
            SecondaryButton(
              label: l10n.receiveReject,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the [IncomingTransferDialog]; resolves to the user's decision
/// (`true` = accept, `false` = decline, `null` if dismissed). Not dismissible by
/// tapping outside — the receiver must explicitly decide (FR-007).
Future<bool?> showIncomingTransferDialog(
  BuildContext context,
  IncomingOffer offer,
) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => IncomingTransferDialog(offer: offer),
);
