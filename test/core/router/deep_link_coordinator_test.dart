import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/core/router/deep_link_coordinator.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';
import 'package:toastification/toastification.dart';

/// Builds a minimal router whose `/start` page exposes a button that runs
/// [coord].handle(context, uri); `home` and `receive` are stub destinations so
/// the test can assert where the coordinator routed (and the carried extra).
GoRouter _router(DeepLinkCoordinator coord, Uri uri) => GoRouter(
  initialLocation: '/start',
  routes: [
    GoRoute(
      path: '/start',
      builder: (_, _) => Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => coord.handle(context, uri),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, _) => const Scaffold(body: Text('HOME')),
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
    ToastificationWrapper(
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const code = '123456';
  final validUri = Uri.parse('safesend://connect?v=1&code=$code');

  testWidgets('a valid invite routes to Receive carrying the code (FR-012)', (
    tester,
  ) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    await _pump(tester, _router(coord, validUri));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('RECEIVE:$code'), findsOneWidget);
  });

  testWidgets('a malformed invite lands on Home, not Receive (FR-013)', (
    tester,
  ) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    await _pump(tester, _router(coord, Uri.parse('safesend://nope?x=1')));

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(
      const Duration(seconds: 4),
    ); // navigate + drain toast timer

    expect(find.text('HOME'), findsOneWidget);
    expect(find.textContaining('RECEIVE:'), findsNothing);
  });

  testWidgets('the host tapping its own invite does not navigate (FR-015)', (
    tester,
  ) async {
    final registry = ActiveHostingRegistryImpl()..setHosting(code);
    final coord = DeepLinkCoordinator(registry);
    await _pump(tester, _router(coord, validUri));

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4)); // drain toast timer

    // Still on the start screen (no Receive / Home navigation).
    expect(find.text('go'), findsOneWidget);
    expect(find.text('RECEIVE:$code'), findsNothing);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('handling a link prints neither the code nor the URL '
      '(Constitution I / FR-021)', (tester) async {
    final coord = DeepLinkCoordinator(ActiveHostingRegistryImpl());
    final logs = <String>[];
    await runZoned(
      () async {
        await _pump(tester, _router(coord, validUri));
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      },
      zoneSpecification: ZoneSpecification(
        print: (_, _, _, line) => logs.add(line),
      ),
    );

    final joined = logs.join('\n');
    expect(joined.contains(code), isFalse);
    expect(joined.contains('safesend://'), isFalse);
  });
}
