import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// App shell hosting the 3-tab bottom navigation over the [StatefulShellRoute]
/// branches (Home / History / Settings). Send/Receive flows are pushed outside
/// the shell and therefore hide this bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  void _goBranch(int index) => shell.goBranch(
    index,
    initialLocation: index == shell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgBase,
          border: Border(top: BorderSide(color: c.borderDefault)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: _goBranch,
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: const Icon(LucideIcons.house),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.history),
              label: l10n.navHistory,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.settings),
              label: l10n.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
