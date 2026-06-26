import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/features/home/presentation/widgets/home_sections.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'Home "Thiết bị gần" → receive route with openNearby (#009 FR-015)',
    (tester) async {
      ReceiveEntryRequest? captured;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: SingleChildScrollView(child: HomeQuickActions()),
            ),
          ),
          GoRoute(
            path: AppRoutes.receive,
            builder: (_, state) {
              captured = state.extra as ReceiveEntryRequest?;
              return const Scaffold();
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Nearby devices'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.openNearby, isTrue);
      expect(captured!.openScanner, isFalse);
    },
  );
}
