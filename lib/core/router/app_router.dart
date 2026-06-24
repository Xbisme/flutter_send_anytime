import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/app/view/app_shell.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/features/history/presentation/history_page.dart';
import 'package:safe_send/features/home/presentation/home_page.dart';
import 'package:safe_send/features/receive/presentation/receive_page.dart';
import 'package:safe_send/features/send/presentation/send_page.dart';
import 'package:safe_send/features/settings/presentation/settings_page.dart';
import 'package:safe_send/features/splash/presentation/splash_page.dart';

/// Builds a fresh app router. Three tabs live inside a [StatefulShellRoute];
/// Send/Receive are top-level routes outside the shell so the bottom nav is
/// hidden for them. Scheme `safesend://` is reserved (no handlers in #001).
///
/// A factory (not a singleton) so each widget test gets an isolated instance.
GoRouter createAppRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) => AppShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (_, _) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (_, _) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.send,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const SendPage(),
      ),
      GoRoute(
        path: AppRoutes.receive,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ReceivePage(),
      ),
    ],
  );
}

/// The production router instance.
final GoRouter appRouter = createAppRouter();
