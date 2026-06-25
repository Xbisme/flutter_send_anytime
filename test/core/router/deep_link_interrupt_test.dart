import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/core/router/deep_link_coordinator.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// A page that triggers `coord.handle(context, uri)` from a button — so the
/// coordinator reads *this* route as the current location.
Widget _trigger(DeepLinkCoordinator coord, Uri uri) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: ElevatedButton(
        onPressed: () => coord.handle(context, uri),
        child: const Text('go'),
      ),
    ),
  ),
);

GoRouter _router(
  DeepLinkCoordinator coord,
  Uri uri, {
  required String initial,
}) => GoRouter(
  initialLocation: initial,
  routes: [
    GoRoute(path: '/start', builder: (_, _) => _trigger(coord, uri)),
    GoRoute(
      path: AppRoutes.sendProgress,
      builder: (_, _) => _trigger(coord, uri),
    ),
    GoRoute(
      path: AppRoutes.receive,
      builder: (_, state) {
        final req = state.extra as ReceiveEntryRequest?;
        return Scaffold(body: Text('RECEIVE:${req?.autoJoinCode}'));
      },
    ),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final uri = Uri.parse('safesend://connect?v=1&code=123456');

  testWidgets('during a transfer, confirming leaves and opens the invite '
      '(FR-014)', (tester) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    await _pump(
      tester,
      _router(coord, uri, initial: AppRoutes.sendProgress),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Leave and open link'), findsOneWidget); // dialog shown

    await tester.tap(find.text('Leave and open link'));
    await tester.pumpAndSettle();

    expect(find.text('RECEIVE:123456'), findsOneWidget);
  });

  testWidgets('during a transfer, cancelling keeps the transfer (FR-014)', (
    tester,
  ) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    await _pump(
      tester,
      _router(coord, uri, initial: AppRoutes.sendProgress),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep transferring'));
    await tester.pumpAndSettle();

    // No navigation to Receive — still on the (progress) trigger page.
    expect(find.text('RECEIVE:123456'), findsNothing);
    expect(find.text('go'), findsOneWidget);
  });

  testWidgets('off a transfer screen, no confirm dialog appears (FR-014)', (
    tester,
  ) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    await _pump(tester, _router(coord, uri, initial: '/start'));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Leave and open link'), findsNothing); // no dialog
    expect(find.text('RECEIVE:123456'), findsOneWidget);
  });
}
