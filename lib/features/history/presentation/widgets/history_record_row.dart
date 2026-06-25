import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// A single transfer in the History list (#006, US1). Direction-colored avatar
/// (sent=accent / received=info), generic peer label, a mono meta line
/// (file count · size · non-completed status), and the time.
class HistoryRecordRow extends StatelessWidget {
  const HistoryRecordRow({required this.record, this.onTap, super.key});

  final TransferRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sent = record.direction == TransferDirection.sent;

    final title = record.peerLabel.isNotEmpty
        ? record.peerLabel
        : (sent ? l10n.historyPeerReceiver : l10n.historyPeerSender);

    final statusLabel = switch (record.status) {
      TransferRecordStatus.completed => null,
      TransferRecordStatus.partial => l10n.historyStatusPartial,
      TransferRecordStatus.failed => l10n.historyStatusFailed,
      TransferRecordStatus.cancelled => l10n.historyStatusCancelled,
    };
    final meta = [
      l10n.historyFilesCount(record.fileCount),
      Formatters.bytes(record.totalBytes),
      ?statusLabel,
    ].join(' · ');

    return Semantics(
      button: onTap != null,
      label: '$title, $meta',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.x4 - 2),
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: AppRadii.cardRadius,
              boxShadow: isDark ? AppShadow.softDark : AppShadow.softLight,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sent
                        ? c.accentSubtle
                        : AppColors.info.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sent ? LucideIcons.arrowUpRight : LucideIcons.arrowDownLeft,
                    size: 18,
                    color: sent ? c.accent : AppColors.info,
                  ),
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.mono(
                          size: 11,
                          color: record.status == TransferRecordStatus.completed
                              ? c.textMuted
                              : AppColors.info,
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Text(
                  Formatters.timeOfDay(record.createdAt.toLocal()),
                  style: AppTypography.mono(
                    size: 11,
                    color: c.textMuted,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
