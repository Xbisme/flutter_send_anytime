import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Pure builder that turns the persisted transfer history (#006) into the real
/// Home dashboard view-model (#012). Deterministic + I/O-free → directly
/// unit-testable. `now` is injected (never `DateTime.now()` inline) so the
/// monthly count is testable (analyze U1).
abstract final class HomeDashboardBuilder {
  /// Home preview caps per section (R6) — the full set is reached via See-all.
  static const photosCap = 6;
  static const videosCap = 4;
  static const filesCap = 4;
  static const recentTransfersCap = 5;

  /// Build the dashboard from a newest-first list of [records].
  static HomeDashboard build(
    List<TransferRecord> records, {
    required DateTime now,
  }) {
    var sentBytes = 0;
    var receivedBytes = 0;
    var monthlyCount = 0;
    var photoCount = 0;
    var videoCount = 0;
    var fileCount = 0;
    final images = <MediaItem>[];
    final videos = <MediaItem>[];
    final files = <MediaItem>[];
    final transfers = <TransferGroupModel>[];

    for (final record in records) {
      // Only successfully-transferred outcomes count (FR-012 / Assumptions):
      // completed fully; partial → kept files; failed/cancelled excluded.
      final status = record.status;
      if (status != TransferRecordStatus.completed &&
          status != TransferRecordStatus.partial) {
        continue;
      }

      final created = record.createdAt.toLocal();
      if (created.year == now.year && created.month == now.month) {
        monthlyCount++;
      }

      if (transfers.length < recentTransfersCap) {
        transfers.add(_transferRow(record));
      }

      for (final file in record.includedFiles) {
        if (record.direction == TransferDirection.sent) {
          sentBytes += file.size;
        } else {
          receivedBytes += file.size;
        }

        final category = FileCategory.of(file);
        final item = _item(record, file, category);
        switch (category) {
          case MediaCategory.photos:
            photoCount++;
            if (images.length < photosCap) images.add(item);
          case MediaCategory.videos:
            videoCount++;
            if (videos.length < videosCap) videos.add(item);
          case MediaCategory.files:
            fileCount++;
            if (files.length < filesCap) files.add(item);
        }
      }
    }

    final total = sentBytes + receivedBytes;
    return HomeDashboard(
      summary: TransferSummary(
        sentBytes: sentBytes,
        receivedBytes: receivedBytes,
        monthlyTransferCount: monthlyCount,
        progressFraction: total == 0 ? 0 : receivedBytes / total,
      ),
      stats: [
        StatTileModel(category: MediaCategory.photos, count: photoCount),
        StatTileModel(category: MediaCategory.videos, count: videoCount),
        StatTileModel(category: MediaCategory.files, count: fileCount),
      ],
      recentImages: images,
      recentVideos: videos,
      recentFiles: files,
      recentTransfers: transfers,
    );
  }

  /// All counted items of [category] across [records], newest-first, uncapped
  /// (backs the See-all screen — FR-009).
  static List<MediaItem> mediaItems(
    List<TransferRecord> records,
    MediaCategory category,
  ) {
    final items = <MediaItem>[];
    for (final record in records) {
      final status = record.status;
      if (status != TransferRecordStatus.completed &&
          status != TransferRecordStatus.partial) {
        continue;
      }
      for (final file in record.includedFiles) {
        if (FileCategory.of(file) == category) {
          items.add(_item(record, file, category));
        }
      }
    }
    return items;
  }

  static MediaItem _item(
    TransferRecord record,
    RecordedFile file,
    MediaCategory category,
  ) => MediaItem(
    category: category,
    name: file.name,
    sizeLabel: Formatters.bytes(file.size),
    ext: file.ext,
    record: record,
    localPath: file.path,
  );

  static TransferGroupModel _transferRow(TransferRecord record) =>
      TransferGroupModel(
        direction: record.direction,
        title: record.files.length == 1
            ? record.files.first.name
            : '${record.fileCount} tệp',
        meta: Formatters.bytes(record.totalBytes),
        time: Formatters.timeOfDay(record.createdAt.toLocal()),
        record: record,
      );
}
