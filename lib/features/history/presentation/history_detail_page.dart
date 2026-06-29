import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/presentation/viewers/file_open_coordinator.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/history/domain/usecases/delete_record_usecase.dart';
import 'package:safe_send/features/history/domain/usecases/resend_availability_usecase.dart';
import 'package:safe_send/features/history/presentation/history_confirm.dart';
import 'package:safe_send/features/history/presentation/history_l10n.dart';

/// History record detail (#006, US3/US5). Shows the full per-file list and all
/// recorded metadata, plus per-record actions: re-send (sent, all-or-nothing),
/// open a received file, share received files, and delete (record-only).
class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({required this.record, super.key});

  final TransferRecord record;

  /// Open a received file: in-app viewer for a supported type, else OS
  /// open/share, else "unavailable" (#013, FR-001). Only wired on the received
  /// side (the open button is hidden for sent records).
  Future<void> _openFile(BuildContext context, RecordedFile file) =>
      FileOpenCoordinator.openTransferredFile(
        context,
        name: file.name,
        path: file.path,
        mimeType: file.mimeType,
        isReceived: true,
      );

  Future<void> _share(BuildContext context) async {
    final paths = record.includedFiles
        .map((f) => f.path)
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    await getIt<ReceivedFilesService>().share(paths);
  }

  void _resend(BuildContext context) {
    final sources = getIt<ResendAvailabilityUseCase>().toSources(record);
    unawaited(context.push(AppRoutes.send, extra: sources));
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await historyConfirm(
      context,
      title: l10n.historyDeleteConfirmTitle,
      body: l10n.historyDeleteConfirmBody,
      confirmLabel: l10n.historyActionDelete,
    );
    if (!confirmed || !context.mounted) return;
    await getIt<DeleteRecordUseCase>().call(record.id);
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final sent = record.direction == TransferDirection.sent;
    final dt = record.createdAt.toLocal();
    final canResend =
        sent && getIt<ResendAvailabilityUseCase>().isAvailable(record);
    final hasOpenableFiles =
        !sent && record.includedFiles.any((f) => f.path != null);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowAppBar(
              title: l10n.historyDetailTitle,
              onLeading: () => context.pop(),
              leadingSemanticLabel: l10n.historyBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x5,
                  0,
                  AppSpacing.x5,
                  AppSpacing.x6,
                ),
                children: [
                  Text(
                    sent
                        ? l10n.historyDirectionSent
                        : l10n.historyDirectionReceived,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  _MetaField(
                    label: l10n.historyFieldStatus,
                    value: record.status.label(l10n),
                  ),
                  _MetaField(
                    label: l10n.historyFieldMethod,
                    value: record.pairingMethod.label(l10n),
                  ),
                  _MetaField(
                    label: l10n.historyFieldDate,
                    value:
                        '${DateFormat.yMMMMd(locale).format(dt)} · '
                        '${DateFormat.Hm(locale).format(dt)}',
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    l10n.historyFieldFiles,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.x2),
                  for (final file in record.files) ...[
                    Opacity(
                      opacity: file.included ? 1 : 0.5,
                      child: FileRow(
                        name: file.name,
                        ext: file.ext,
                        meta: Formatters.bytes(file.size),
                        trailing: (!sent && file.included && file.path != null)
                            ? IconButton(
                                icon: const Icon(LucideIcons.externalLink),
                                iconSize: 18,
                                tooltip: l10n.historyActionOpen,
                                onPressed: () => _openFile(context, file),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x4,
              ),
              child: Column(
                children: [
                  if (canResend)
                    PrimaryButton(
                      label: l10n.historyActionResend,
                      icon: LucideIcons.send,
                      onPressed: () => _resend(context),
                    ),
                  if (hasOpenableFiles) ...[
                    if (canResend) const SizedBox(height: AppSpacing.x2),
                    SecondaryButton(
                      label: l10n.historyActionShare,
                      icon: LucideIcons.share2,
                      onPressed: () => _share(context),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.x2),
                  DangerButton(
                    label: l10n.historyActionDelete,
                    icon: LucideIcons.trash2,
                    onPressed: () => _delete(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaField extends StatelessWidget {
  const _MetaField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.mono(size: 13, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
