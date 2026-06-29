import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/presentation/viewers/file_open_coordinator.dart';
import 'package:safe_send/core/utils/file_viewer.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('viewer_coord'));
  tearDown(() => dir.deleteSync(recursive: true));

  String make(String name) {
    final f = File('${dir.path}/$name')..writeAsStringSync('x');
    return f.path;
  }

  group('FileOpenCoordinator.viewableRequestFor (decision table)', () {
    test('received + on disk + supported → a ViewerRequest of that kind', () {
      final req = FileOpenCoordinator.viewableRequestFor(
        name: 'photo.jpg',
        path: make('photo.jpg'),
        mimeType: 'image/jpeg',
        isReceived: true,
      );
      expect(req, isNotNull);
      expect(req!.kind, ViewerKind.image);
    });

    test('audio / pdf / text resolve to their kinds', () {
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'a.mp3',
          path: make('a.mp3'),
          mimeType: null,
          isReceived: true,
        )?.kind,
        ViewerKind.audio,
      );
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'a.pdf',
          path: make('a.pdf'),
          mimeType: null,
          isReceived: true,
        )?.kind,
        ViewerKind.pdf,
      );
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'a.dart',
          path: make('a.dart'),
          mimeType: null,
          isReceived: true,
        )?.kind,
        ViewerKind.text,
      );
    });

    test('sent file → null (always OS fallback, FR-001)', () {
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'photo.jpg',
          path: make('photo.jpg'),
          mimeType: 'image/jpeg',
          isReceived: false,
        ),
        isNull,
      );
    });

    test('missing file → null (FR-014)', () {
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'gone.jpg',
          path: '${dir.path}/gone.jpg',
          mimeType: 'image/jpeg',
          isReceived: true,
        ),
        isNull,
      );
    });

    test('null path → null', () {
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'x.jpg',
          path: null,
          mimeType: null,
          isReceived: true,
        ),
        isNull,
      );
    });

    test('unsupported type → null (OS fallback, FR-004)', () {
      expect(
        FileOpenCoordinator.viewableRequestFor(
          name: 'archive.zip',
          path: make('archive.zip'),
          mimeType: null,
          isReceived: true,
        ),
        isNull,
      );
    });
  });
}
