import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/router/app_router.dart';
import '../helpers/fake_history_repository.dart';

// Widget tests render in the test-default locale (English). Vietnamese-primary
// correctness is verified separately in test/l10n/localization_test.dart.
Future<void> _settleToHome(WidgetTester tester) async {
  await tester.pumpWidget(SafeSendApp(router: createAppRouter()));
  // Advance past the static splash timer, then settle the Home load.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    getIt
      ..unregister<TransferHistoryRepository>()
      ..registerFactory<TransferHistoryRepository>(FakeHistoryRepository.new);
  });
  tearDown(() async => getIt.reset());

  group('Navigation shell (US1)', () {
    testWidgets('opens on Home with exactly 3 tabs', (tester) async {
      await _settleToHome(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(3));
      expect(bar.selectedIndex, 0);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('History'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('tapping History shows its placeholder empty state', (
      tester,
    ) async {
      await _settleToHome(tester);

      await tester.tap(find.text('History').last);
      await tester.pumpAndSettle();

      expect(find.text('No transfers yet'), findsOneWidget);
    });

    testWidgets('tapping Settings shows the settings placeholder', (
      tester,
    ) async {
      await _settleToHome(tester);

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.text("An's iPhone 15"), findsOneWidget);
      expect(find.textContaining('Safe Send v1.0.0'), findsOneWidget);
    });
  });
}
