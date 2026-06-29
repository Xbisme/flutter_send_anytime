import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_document.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_viewer_cubit.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_error_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

/// Readable text/code viewer (#013, US3/FR-010). Selectable text, monospace for
/// code; a large file shows a truncated-with-notice preview (FR-010a).
class TextViewerPage extends StatelessWidget {
  const TextViewerPage({required this.request, super.key});

  final ViewerRequest request;

  bool get _isCode {
    final dot = request.name.lastIndexOf('.');
    if (dot < 0) return false;
    return kCodeExts.contains(request.name.substring(dot + 1).toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return BlocProvider<TextViewerCubit>(
      create: (_) {
        final cubit = getIt<TextViewerCubit>();
        unawaited(cubit.open(request.path));
        return cubit;
      },
      child: Scaffold(
        backgroundColor: c.bgBase,
        body: Column(
          children: [
            ViewerTopBar(title: request.name, sharePath: request.path),
            Expanded(
              child: BlocBuilder<TextViewerCubit, AppState<TextDocument>>(
                builder: (context, state) => switch (state) {
                  AppError<TextDocument>() => ViewerErrorView(
                    message: context.l10n.viewerDocumentError,
                    path: request.path,
                  ),
                  AppLoaded<TextDocument>(:final data) => _TextBody(
                    document: data,
                    isCode: _isCode,
                  ),
                  _ => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextBody extends StatelessWidget {
  const _TextBody({required this.document, required this.isCode});

  final TextDocument document;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final textStyle = isCode
        ? AppTypography.mono(
            size: 13,
            color: c.textPrimary,
            weight: FontWeight.w400,
          )
        : Theme.of(context).textTheme.bodyMedium;
    return Column(
      children: [
        if (document.truncated) _TruncatedBanner(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: SelectableText(document.text, style: textStyle),
          ),
        ),
      ],
    );
  }
}

class _TruncatedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      color: c.surfaceSunken,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x2,
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 16, color: c.textMuted),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              context.l10n.viewerTextTruncated,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
