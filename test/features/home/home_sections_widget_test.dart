import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/presentation/widgets/home_sections.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

TransferRecord _record = TransferRecord(
  id: 'r1',
  direction: TransferDirection.received,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 1,
  totalBytes: 1,
  createdAt: DateTime(2026, 6, 20),
);

MediaItem _photo(String name) => MediaItem(
  category: MediaCategory.photos,
  name: name,
  sizeLabel: '2 MB',
  record: _record,
);

TransferRecord? _tappedDetail;

Future<void> _pump(WidgetTester tester, Widget child) async {
  _tappedDetail = null;
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: SingleChildScrollView(child: child)),
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
  group('Home sections (US1)', () {
    testWidgets('hero shows real totals + monthly count', (tester) async {
      await _pump(
        tester,
        const HomeHeroCard(
          summary: TransferSummary(
            sentBytes: 0,
            receivedBytes: 0,
            monthlyTransferCount: 7,
            progressFraction: 0,
          ),
        ),
      );
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Received'), findsOneWidget);
      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('stat tiles show real counts', (tester) async {
      await _pump(
        tester,
        const HomeStatsRow(
          stats: [
            StatTileModel(category: MediaCategory.photos, count: 5),
            StatTileModel(category: MediaCategory.videos, count: 2),
            StatTileModel(category: MediaCategory.files, count: 9),
          ],
        ),
      );
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
    });
  });

  group('Home recent media (US2)', () {
    testWidgets('renders real photos and taps through to detail', (
      tester,
    ) async {
      await _pump(
        tester,
        HomeRecentImages(images: [_photo('holiday.jpg')], onSeeAll: () {}),
      );
      expect(find.text('holiday.jpg'), findsOneWidget);

      await tester.tap(find.text('holiday.jpg'));
      await tester.pumpAndSettle();
      expect(_tappedDetail?.id, 'r1');
    });

    testWidgets('empty photo section shows empty state, no See all', (
      tester,
    ) async {
      var seeAllTapped = false;
      await _pump(
        tester,
        HomeRecentImages(images: const [], onSeeAll: () => seeAllTapped = true),
      );
      expect(find.text('No photos yet.'), findsOneWidget);
      expect(find.text('See all'), findsNothing);
      expect(seeAllTapped, isFalse);
    });

    testWidgets('See all affordance fires its callback', (tester) async {
      var seeAllTapped = false;
      await _pump(
        tester,
        HomeRecentImages(
          images: [_photo('a.jpg')],
          onSeeAll: () => seeAllTapped = true,
        ),
      );
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(seeAllTapped, isTrue);
    });
  });
}
