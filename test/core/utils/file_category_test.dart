import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/utils/file_category.dart';

RecordedFile _file(String name, {String? mime}) =>
    RecordedFile(name: name, size: 1, mimeType: mime);

void main() {
  group('FileCategory.of', () {
    test('classifies by MIME when present', () {
      expect(
        FileCategory.of(_file('x', mime: 'image/png')),
        MediaCategory.photos,
      );
      expect(
        FileCategory.of(_file('x', mime: 'video/mp4')),
        MediaCategory.videos,
      );
      expect(
        FileCategory.of(_file('x', mime: 'application/pdf')),
        MediaCategory.files,
      );
    });

    test('falls back to extension when MIME is absent', () {
      expect(FileCategory.of(_file('beach.JPG')), MediaCategory.photos);
      expect(FileCategory.of(_file('clip.mov')), MediaCategory.videos);
      expect(FileCategory.of(_file('notes.pdf')), MediaCategory.files);
      expect(FileCategory.of(_file('archive.zip')), MediaCategory.files);
    });

    test('unknown / extensionless → files', () {
      expect(FileCategory.of(_file('README')), MediaCategory.files);
      expect(FileCategory.of(_file('data.xyz')), MediaCategory.files);
    });

    test('empty MIME falls through to extension', () {
      expect(
        FileCategory.of(_file('pic.heic', mime: '')),
        MediaCategory.photos,
      );
    });
  });
}
