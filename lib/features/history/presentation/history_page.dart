import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/presentation/feedback/app_empty_view.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// History tab placeholder (#001). Real transfer history lands in #006.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.historyTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            Expanded(
              child: AppEmptyView(
                icon: LucideIcons.history,
                title: l10n.historyEmptyTitle,
                body: l10n.historyEmptyBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
