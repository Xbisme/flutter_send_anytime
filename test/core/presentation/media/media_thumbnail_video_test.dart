import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/presentation/media/media_thumbnail.dart';
import 'package:safe_send/core/services/media/video_thumbnail_service.dart';
import 'package:safe_send/core/utils/file_category.dart';

import '../../../helpers/pump_app.dart';

class _FakeThumbs implements VideoThumbnailService {
  _FakeThumbs(this.result);
  final Result<String?> result;
  @override
  Future<Result<String?>> thumbnailPath(String videoPath) async => result;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('thumb_widget'));
  tearDown(() async {
    await getIt.reset();
    dir.deleteSync(recursive: true);
  });

  void register(Result<String?> r) =>
      getIt.registerFactory<VideoThumbnailService>(() => _FakeThumbs(r));

  // The thumbnail resolves asynchronously then setState → rebuild. Poll-until
  // ([target] non-null) so it is robust to resolution latency under load.
  Future<void> pumpResolved(
    WidgetTester tester,
    String path, {
    Finder? target,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpApp(
        MediaThumbnail(category: MediaCategory.videos, localPath: path),
      );
      for (var i = 0; i < 100; i++) {
        await tester.pump();
        if (target == null || target.evaluate().isNotEmpty) return;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
  }

  testWidgets('video tile shows generated frame when service returns a path', (
    tester,
  ) async {
    final video = File('${dir.path}/clip.mp4')..writeAsBytesSync([1]);
    final thumb = File('${dir.path}/thumb.jpg')..writeAsBytesSync([0]);
    register(Result.success(thumb.path));

    await pumpResolved(tester, video.path, target: find.byType(Image));

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('falls back to the play-glyph icon when no thumbnail', (
    tester,
  ) async {
    final video = File('${dir.path}/clip.mp4')..writeAsBytesSync([1]);
    register(const Result.success(null));

    await pumpResolved(tester, video.path);

    expect(find.byIcon(LucideIcons.video), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
