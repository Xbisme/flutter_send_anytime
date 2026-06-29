import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/utils/file_viewer.dart';

void main() {
  group('ViewerResolver.of — by MIME', () {
    test('maps each MIME family to its kind', () {
      expect(ViewerResolver.of('x', mimeType: 'image/png'), ViewerKind.image);
      expect(ViewerResolver.of('x', mimeType: 'video/mp4'), ViewerKind.video);
      expect(ViewerResolver.of('x', mimeType: 'audio/mpeg'), ViewerKind.audio);
      expect(
        ViewerResolver.of('x', mimeType: 'application/pdf'),
        ViewerKind.pdf,
      );
      expect(ViewerResolver.of('x', mimeType: 'text/plain'), ViewerKind.text);
    });

    test('non-text application MIME falls through to extension', () {
      // application/json has no MIME branch → resolves by .json extension.
      expect(
        ViewerResolver.of('data.json', mimeType: 'application/json'),
        ViewerKind.text,
      );
    });
  });

  group('ViewerResolver.of — by extension', () {
    test('image / video reuse the #012 sets', () {
      expect(ViewerResolver.of('beach.JPG'), ViewerKind.image);
      expect(ViewerResolver.of('a.heic'), ViewerKind.image);
      expect(ViewerResolver.of('clip.MOV'), ViewerKind.video);
    });

    test('audio splits out of the #012 files bucket', () {
      expect(ViewerResolver.of('song.mp3'), ViewerKind.audio);
      expect(ViewerResolver.of('voice.m4a'), ViewerKind.audio);
      expect(ViewerResolver.of('take.wav'), ViewerKind.audio);
    });

    test('pdf and text/code', () {
      expect(ViewerResolver.of('report.pdf'), ViewerKind.pdf);
      expect(ViewerResolver.of('notes.txt'), ViewerKind.text);
      expect(ViewerResolver.of('main.dart'), ViewerKind.text);
      expect(ViewerResolver.of('config.yaml'), ViewerKind.text);
    });

    test('unknown / extensionless / office → unsupported', () {
      expect(ViewerResolver.of('archive.zip'), ViewerKind.unsupported);
      expect(ViewerResolver.of('sheet.xlsx'), ViewerKind.unsupported);
      expect(ViewerResolver.of('doc.docx'), ViewerKind.unsupported);
      expect(ViewerResolver.of('README'), ViewerKind.unsupported);
      expect(ViewerResolver.of('trailingdot.'), ViewerKind.unsupported);
    });
  });

  group('ViewerResolver.isViewable', () {
    test('true for every kind except unsupported', () {
      for (final k in ViewerKind.values) {
        expect(
          ViewerResolver.isViewable(k),
          k != ViewerKind.unsupported,
          reason: '$k',
        );
      }
    });
  });
}
