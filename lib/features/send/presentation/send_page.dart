import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/presentation/scaffolding/coming_soon_view.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Send flow placeholder (#001) — full-screen, nav-less. Replaced in #004.
class SendPage extends StatelessWidget {
  const SendPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowAppBar(
              title: l10n.actionSend,
              onLeading: () => context.pop(),
              leadingSemanticLabel: l10n.commonBack,
            ),
            Expanded(
              child: ComingSoonView(
                icon: LucideIcons.send,
                title: l10n.comingSoonTitle,
                body: l10n.sendComingSoonBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
