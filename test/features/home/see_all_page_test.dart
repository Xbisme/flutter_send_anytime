import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/presentation/see_all/see_all_page.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

import '../../helpers/fake_history_repository.dart';

TransferRecord _photoRecord = TransferRecord(
  id: 'r1',
  direction: TransferDirection.received,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 1,
  totalBytes: 1234,
  createdAt: DateTime(2026, 6, 20),
  files: const [
    RecordedFile(name: 'holiday.jpg', size: 1234, mimeType: 'image/jpeg'),
  ],
);

TransferRecord? _tappedDetail;

Future<void> _pump(WidgetTester tester, MediaCategory category) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => SeeAllPage(category: category),
      ),
      GoRoute(
        path: AppRoutes.historyDetail,
        builder: (_, state) {
          _tappedDetail = state.extra as TransferRecord?;
          return const Scaffold(body: Text('detail'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('en'),
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late FakeHistoryRepository fake;

  setUp(() async {
    _tappedDetail = null;
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    fake = FakeHistoryRepository();
    getIt
      ..unregister<TransferHistoryRepository>()
      ..registerFactory<TransferHistoryRepository>(() => fake);
  });
  tearDown(() async => getIt.reset());

  group('SeeAllPage', () {
    testWidgets('lists all items of the category and navigates to detail', (
      tester,
    ) async {
      fake.records = [_photoRecord];
      await _pump(tester, MediaCategory.photos);

      expect(find.text('All photos'), findsOneWidget);
      expect(find.text('holiday.jpg'), findsOneWidget);

      await tester.tap(find.text('holiday.jpg'));
      await tester.pumpAndSettle();
      expect(_tappedDetail, isNotNull);
      expect(_tappedDetail!.id, 'r1');
    });

    testWidgets('shows an empty state when the category has no items', (
      tester,
    ) async {
      fake.records = const [];
      await _pump(tester, MediaCategory.videos);

      expect(find.text('No videos yet.'), findsOneWidget);
    });
  });
}
