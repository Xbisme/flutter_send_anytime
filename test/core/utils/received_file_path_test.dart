import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/utils/received_file_path.dart';

void main() {
  late Directory base;

  setUp(() {
    base = Directory.systemTemp.createTempSync('rfp');
    ReceivedFilePath.documentsBase = base.path;
  });
  tearDown(() {
    ReceivedFilePath.documentsBase = null;
    base.deleteSync(recursive: true);
  });

  test('returns the stored path when it still exists', () {
    final f = File('${base.path}/SafeSend/keep.jpg')
      ..createSync(recursive: true);
    expect(ReceivedFilePath.resolve(f.path), f.path);
  });

  test('re-roots a stale container path onto the current documents base', () {
    // The file lives under the *current* base...
    final real = File('${base.path}/SafeSend/photo.jpg')
      ..createSync(recursive: true);
    // ...but the stored path points at an old container UUID.
    const stale =
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/SafeSend/photo.jpg';
    expect(File(stale).existsSync(), false);
    expect(ReceivedFilePath.resolve(stale), real.path);
  });

  test('nested subdir under SafeSend is preserved', () {
    final real = File('${base.path}/SafeSend/sub/clip.mp4')
      ..createSync(recursive: true);
    const stale = '/old/Documents/SafeSend/sub/clip.mp4';
    expect(ReceivedFilePath.resolve(stale), real.path);
  });

  test('no SafeSend marker → returned unchanged', () {
    expect(
      ReceivedFilePath.resolve('/tmp/sent/source.png'),
      '/tmp/sent/source.png',
    );
  });

  test('unresolvable (file truly gone) → returned unchanged', () {
    const stale = '/old/Documents/SafeSend/missing.jpg';
    expect(ReceivedFilePath.resolve(stale), stale);
  });

  test('null base → returned unchanged', () {
    ReceivedFilePath.documentsBase = null;
    const stale = '/old/Documents/SafeSend/x.jpg';
    expect(ReceivedFilePath.resolve(stale), stale);
  });
}
