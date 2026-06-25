import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/app/view/app_shell.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/features/history/presentation/history_detail_page.dart';
import 'package:safe_send/features/history/presentation/history_page.dart';
import 'package:safe_send/features/home/presentation/home_page.dart';
import 'package:safe_send/features/pairing/presentation/connect/connect_page.dart';
import 'package:safe_send/features/pairing/presentation/debug/pairing_debug_page.dart';
import 'package:safe_send/features/pairing/presentation/scan/qr_scan_page.dart';
import 'package:safe_send/features/receive/presentation/pages/receive_entry_page.dart';
import 'package:safe_send/features/receive/presentation/pages/receive_transfer_page.dart';
import 'package:safe_send/features/receive/presentation/receive_progress_args.dart';
import 'package:safe_send/features/send/presentation/pages/send_selection_page.dart';
import 'package:safe_send/features/send/presentation/pages/send_transfer_page.dart';
import 'package:safe_send/features/send/presentation/send_progress_args.dart';
import 'package:safe_send/features/settings/presentation/settings_page.dart';
import 'package:safe_send/features/splash/presentation/splash_page.dart';

/// Builds a fresh app router. Three tabs live inside a [StatefulShellRoute];
/// Send/Receive are top-level routes outside the shell so the bottom nav is
/// hidden for them. Scheme `safesend://` is reserved (no handlers in #001).
///
/// [includeDevRoutes] mounts the dev-flavor-only pairing debug surface (#003,
/// FR-021a). A factory (not a singleton) so each widget test gets an isolated
/// instance.
GoRouter createAppRouter({bool includeDevRoutes = false}) {
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
        builder: (_, state) =>
            SendSelectionPage(initialSources: state.extra as List<FileSource>?),
      ),
      GoRoute(
        path: AppRoutes.receive,
        parentNavigatorKey: rootKey,
        builder: (_, state) => ReceiveEntryPage(
          request:
              state.extra as ReceiveEntryRequest? ??
              const ReceiveEntryRequest(),
        ),
      ),
      GoRoute(
        path: AppRoutes.connect,
        parentNavigatorKey: rootKey,
        builder: (_, state) => ConnectPage(
          request:
              state.extra as ConnectRequest? ??
              const ConnectRequest(role: TransferRole.sender),
        ),
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const QrScanPage(),
      ),
      GoRoute(
        path: AppRoutes.sendProgress,
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            SendTransferPage(args: state.extra! as SendProgressArgs),
      ),
      GoRoute(
        path: AppRoutes.receiveProgress,
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            ReceiveTransferPage(args: state.extra! as ReceiveProgressArgs),
      ),
      GoRoute(
        path: AppRoutes.historyDetail,
        parentNavigatorKey: rootKey,
        builder: (_, state) =>
            HistoryDetailPage(record: state.extra! as TransferRecord),
      ),
      if (includeDevRoutes)
        GoRoute(
          path: AppRoutes.pairingDebug,
          parentNavigatorKey: rootKey,
          builder: (_, _) => const PairingDebugPage(),
        ),
    ],
  );
}

/// Whether the dev-flavor debug routes should be mounted. False unless the
/// active flavor is dev (and DI has been configured).
bool _devRoutesEnabled() =>
    getIt.isRegistered<AppConfig>() && getIt<AppConfig>().flavor.isDev;

/// The production router instance.
final GoRouter appRouter = createAppRouter(
  includeDevRoutes: _devRoutesEnabled(),
);
