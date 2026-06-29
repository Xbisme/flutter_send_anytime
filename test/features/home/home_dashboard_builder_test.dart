import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/data/home_dashboard_builder.dart';

TransferRecord _record({
  required String id,
  required TransferDirection direction,
  required TransferRecordStatus status,
  required List<RecordedFile> files,
  DateTime? createdAt,
}) => TransferRecord(
  id: id,
  direction: direction,
  status: status,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: files.length,
  totalBytes: files.fold(0, (a, f) => a + f.size),
  createdAt: createdAt ?? DateTime(2026, 6, 20, 10),
  files: files,
);

RecordedFile _img(String n, int s, {String? path}) =>
    RecordedFile(name: n, size: s, mimeType: 'image/jpeg', path: path);
RecordedFile _vid(String n, int s) =>
    RecordedFile(name: n, size: s, mimeType: 'video/mp4');
RecordedFile _doc(String n, int s) =>
    RecordedFile(name: n, size: s, mimeType: 'application/pdf');

final _now = DateTime(2026, 6, 29, 12);

void main() {
  group('HomeDashboardBuilder.build', () {
    test('sums bytes per direction over counted records', () {
      final d = HomeDashboardBuilder.build([
        _record(
          id: 's',
          direction: TransferDirection.sent,
          status: TransferRecordStatus.completed,
          files: [_img('a.jpg', 100), _doc('b.pdf', 50)],
        ),
        _record(
          id: 'r',
          direction: TransferDirection.received,
          status: TransferRecordStatus.completed,
          files: [_vid('c.mp4', 200)],
        ),
      ], now: _now);

      expect(d.summary.sentBytes, 150);
      expect(d.summary.receivedBytes, 200);
      expect(d.summary.progressFraction, closeTo(200 / 350, 1e-9));
    });

    test('excludes failed/cancelled; partial counts only kept files', () {
      final d = HomeDashboardBuilder.build([
        _record(
          id: 'f',
          direction: TransferDirection.received,
          status: TransferRecordStatus.failed,
          files: [_img('x.jpg', 999)],
        ),
        _record(
          id: 'p',
          direction: TransferDirection.received,
          status: TransferRecordStatus.partial,
          files: [
            _img('kept.jpg', 10),
            const RecordedFile(
              name: 'dropped.jpg',
              size: 90,
              mimeType: 'image/jpeg',
              included: false,
            ),
          ],
        ),
      ], now: _now);

      expect(d.summary.receivedBytes, 10); // only the kept file
      final photos = d.stats.firstWhere(
        (s) => s.category == MediaCategory.photos,
      );
      expect(photos.count, 1);
    });

    test('per-file stat counts by category', () {
      final d = HomeDashboardBuilder.build([
        _record(
          id: 'm',
          direction: TransferDirection.sent,
          status: TransferRecordStatus.completed,
          files: [
            _img('a.jpg', 1),
            _img('b.jpg', 1),
            _vid('c.mp4', 1),
            _doc('d.pdf', 1),
          ],
        ),
      ], now: _now);

      int count(MediaCategory c) =>
          d.stats.firstWhere((s) => s.category == c).count;
      expect(count(MediaCategory.photos), 2);
      expect(count(MediaCategory.videos), 1);
      expect(count(MediaCategory.files), 1);
    });

    test('monthly count uses injected now (current calendar month)', () {
      final d = HomeDashboardBuilder.build([
        _record(
          id: 'this',
          direction: TransferDirection.sent,
          status: TransferRecordStatus.completed,
          files: [_doc('a', 1)],
          createdAt: DateTime(2026, 6, 2),
        ),
        _record(
          id: 'last',
          direction: TransferDirection.sent,
          status: TransferRecordStatus.completed,
          files: [_doc('b', 1)],
          createdAt: DateTime(2026, 5, 30),
        ),
      ], now: _now);

      expect(d.summary.monthlyTransferCount, 1);
    });

    test('preview sections capped; media carries record + localPath', () {
      final files = [
        for (var i = 0; i < 9; i++) _img('p$i.jpg', 1, path: '/x/p$i.jpg'),
      ];
      final d = HomeDashboardBuilder.build([
        _record(
          id: 'big',
          direction: TransferDirection.received,
          status: TransferRecordStatus.completed,
          files: files,
        ),
      ], now: _now);

      expect(d.recentImages, hasLength(HomeDashboardBuilder.photosCap));
      expect(d.recentImages.first.record.id, 'big');
      expect(d.recentImages.first.localPath, '/x/p0.jpg');
      expect(d.recentImages.first.category, MediaCategory.photos);
    });

    test('empty history → zeroed dashboard', () {
      final d = HomeDashboardBuilder.build([], now: _now);
      expect(d.summary.sentBytes, 0);
      expect(d.summary.receivedBytes, 0);
      expect(d.summary.monthlyTransferCount, 0);
      expect(d.summary.progressFraction, 0);
      expect(d.stats, hasLength(3));
      expect(d.recentImages, isEmpty);
      expect(d.recentVideos, isEmpty);
      expect(d.recentFiles, isEmpty);
      expect(d.recentTransfers, isEmpty);
    });
  });

  group('HomeDashboardBuilder.mediaItems', () {
    test(
      'returns all items of a category (uncapped), excludes non-counted',
      () {
        final records = [
          _record(
            id: 'a',
            direction: TransferDirection.received,
            status: TransferRecordStatus.completed,
            files: [for (var i = 0; i < 8; i++) _img('a$i.jpg', 1)],
          ),
          _record(
            id: 'c',
            direction: TransferDirection.received,
            status: TransferRecordStatus.cancelled,
            files: [_img('z.jpg', 1)],
          ),
        ];
        final items = HomeDashboardBuilder.mediaItems(
          records,
          MediaCategory.photos,
        );
        expect(items, hasLength(8)); // cancelled record excluded, no cap
      },
    );
  });
}
