import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/presentation/tiles/quick_action_card.dart';
import 'package:safe_send/core/router/app_router.dart';
import 'package:safe_send/features/receive/presentation/receive_page.dart';
import 'package:safe_send/features/send/presentation/send_page.dart';

// Widget tests render in the test-default locale (English).
Future<void> _settleToHome(WidgetTester tester) async {
  await tester.pumpWidget(SafeSendApp(router: createAppRouter()));
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final text = find.text(label);
  await tester.scrollUntilVisible(
    text,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  final card = find.ancestor(of: text, matching: find.byType(QuickActionCard));
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
  });
  tearDown(() async => getIt.reset());

  group('Home screen (US2)', () {
    testWidgets('renders the branded header and hero summary', (tester) async {
      await _settleToHome(tester);

      expect(find.text('Safe Send'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
    });

    testWidgets('shows the quick-actions section when scrolled into view', (
      tester,
    ) async {
      await _settleToHome(tester);

      await tester.scrollUntilVisible(
        find.text('Quick actions'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Quick actions'), findsOneWidget);
    });

    testWidgets('tapping Send opens a nav-less Coming Soon flow', (
      tester,
    ) async {
      await _settleToHome(tester);
      await _tapAction(tester, 'Send files');

      expect(find.byType(SendPage), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Back returns to Home with the bar restored.
      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(SendPage), findsNothing);
    });

    testWidgets('tapping Receive opens a nav-less Coming Soon flow', (
      tester,
    ) async {
      await _settleToHome(tester);
      await _tapAction(tester, 'Receive files');

      expect(find.byType(ReceivePage), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
