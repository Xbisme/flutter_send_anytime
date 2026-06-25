import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Maps real history records into the Home dashboard's recent-transfers section
/// (#006, US6), replacing the #001 mock for that section. The hero/stat/media
/// sections remain placeholder until later work — this only swaps the recent
/// list, keeping the [HomeDashboard] contract (FR-008/FR-026).
abstract final class HomeHistoryMapper {
  /// Build the recent-transfers section from [records].
  static List<TransferGroupModel> recent(List<TransferRecord> records) => [
    for (final r in records)
      TransferGroupModel(
        direction: r.direction,
        title: r.files.length == 1 ? r.files.first.name : '${r.fileCount} tệp',
        meta: Formatters.bytes(r.totalBytes),
        time: Formatters.timeOfDay(r.createdAt.toLocal()),
        thumbs: const [],
        moreCount: 0,
        record: r,
      ),
  ];

  /// A copy of [base] with its recent-transfers section replaced by [recents].
  static HomeDashboard withRecent(
    HomeDashboard base,
    List<TransferGroupModel> recents,
  ) => HomeDashboard(
    summary: base.summary,
    stats: base.stats,
    recentImages: base.recentImages,
    recentVideos: base.recentVideos,
    recentFiles: base.recentFiles,
    recentTransfers: recents,
  );
}
