import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/media/video_thumbnail_service_impl.dart';

void main() {
  late Directory videoDir;
  late Directory cacheDir;
  var generateCalls = 0;

  setUp(() {
    videoDir = Directory.systemTemp.createTempSync('vt_src');
    cacheDir = Directory.systemTemp.createTempSync('vt_cache');
    generateCalls = 0;
  });
  tearDown(() {
    videoDir.deleteSync(recursive: true);
    cacheDir.deleteSync(recursive: true);
  });

  // Fake generator: writes a 1-byte JPEG into [dir] and returns its path.
  Future<String?> fakeGen(String video, String dir) async {
    generateCalls++;
    final out = File('$dir/gen_$generateCalls.jpg')..writeAsBytesSync([0]);
    return out.path;
  }

  VideoThumbnailServiceImpl service({ThumbnailGenerator? gen}) =>
      VideoThumbnailServiceImpl.test(
        generator: gen ?? fakeGen,
        cacheDirProvider: () async => cacheDir,
      );

  String makeVideo(String name) {
    final f = File('${videoDir.path}/$name')..writeAsBytesSync([1, 2, 3]);
    return f.path;
  }

  String? value(Result<String?> r) => r.fold((v) => v, (_) => null);

  test(
    'cache miss generates + caches; hit reuses (no second generate)',
    () async {
      final s = service();
      final video = makeVideo('clip.mp4');

      final first = await s.thumbnailPath(video);
      expect(value(first), isNotNull);
      expect(File(value(first)!).existsSync(), true);
      expect(generateCalls, 1);

      final second = await s.thumbnailPath(video);
      expect(value(second), value(first));
      expect(generateCalls, 1, reason: 'disk cache hit → no regenerate');
    },
  );

  test('mtime change invalidates the cache (regenerates)', () async {
    final s = service();
    final video = makeVideo('clip.mp4');
    await s.thumbnailPath(video);
    expect(generateCalls, 1);

    // Rewrite the source so its mtime advances.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    File(video).writeAsBytesSync([9, 9, 9, 9]);
    await s.thumbnailPath(video);
    expect(generateCalls, 2);
  });

  test('missing video → success(null), no generate', () async {
    final s = service();
    final r = await s.thumbnailPath('${videoDir.path}/nope.mp4');
    expect(value(r), isNull);
    expect(generateCalls, 0);
  });

  test('generator returning null → success(null) fallback', () async {
    final s = service(gen: (_, _) async => null);
    final r = await s.thumbnailPath(makeVideo('c.mp4'));
    expect(value(r), isNull);
  });
}
