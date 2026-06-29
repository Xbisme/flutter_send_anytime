import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/presentation/media/media_thumbnail.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/core/utils/file_category.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  ),
);

void main() {
  group('MediaThumbnail', () {
    testWidgets('photo with no local path → image icon fallback', (
      tester,
    ) async {
      await _pump(tester, const MediaThumbnail(category: MediaCategory.photos));
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('photo with a missing path → icon fallback', (tester) async {
      await _pump(
        tester,
        const MediaThumbnail(
          category: MediaCategory.photos,
          localPath: '/no/such/file.jpg',
        ),
      );
      expect(find.byIcon(LucideIcons.image), findsOneWidget);
    });

    testWidgets('video → video icon (no real frame)', (tester) async {
      await _pump(
        tester,
        const MediaThumbnail(
          category: MediaCategory.videos,
          localPath: '/anything.mp4',
        ),
      );
      expect(find.byIcon(LucideIcons.video), findsOneWidget);
    });

    testWidgets('file → file icon', (tester) async {
      await _pump(tester, const MediaThumbnail(category: MediaCategory.files));
      expect(find.byIcon(LucideIcons.file), findsOneWidget);
    });

    testWidgets('photo with an existing local file → renders an Image', (
      tester,
    ) async {
      final tmp = File(
        '${Directory.systemTemp.path}/media_thumb_test.png',
      )..writeAsBytesSync(const [0, 1, 2, 3]);
      addTearDown(() => tmp.existsSync() ? tmp.deleteSync() : null);

      await _pump(
        tester,
        MediaThumbnail(category: MediaCategory.photos, localPath: tmp.path),
      );
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
