import 'package:flutter/widgets.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

/// Aggregate of all Home placeholder data (static mock in #001; real data from
/// #006). Immutable presentation view-model.
@immutable
class HomeDashboard {
  const HomeDashboard({
    required this.summary,
    required this.stats,
    required this.recentImages,
    required this.recentVideos,
    required this.recentFiles,
    required this.recentTransfers,
  });

  final TransferSummary summary;
  final List<StatTileModel> stats;
  final List<MediaThumb> recentImages;
  final List<VideoThumb> recentVideos;
  final List<FileItemModel> recentFiles;
  final List<TransferGroupModel> recentTransfers;
}

/// Hero summary totals.
@immutable
class TransferSummary {
  const TransferSummary({
    required this.sentBytes,
    required this.receivedBytes,
    required this.monthlyTransferCount,
    required this.progressFraction,
  });

  final int sentBytes;
  final int receivedBytes;
  final int monthlyTransferCount;
  final double progressFraction;
}

/// Which stat a tile represents.
enum StatKind { photos, videos, files }

@immutable
class StatTileModel {
  const StatTileModel({
    required this.kind,
    required this.count,
    required this.tint,
  });

  final StatKind kind;
  final int count;
  final Color tint;
}

@immutable
class MediaThumb {
  const MediaThumb({
    required this.name,
    required this.sizeLabel,
    required this.gradient,
  });

  final String name;
  final String sizeLabel;
  final Gradient gradient;
}

@immutable
class VideoThumb {
  const VideoThumb({
    required this.name,
    required this.sizeLabel,
    required this.durationLabel,
    required this.gradient,
  });

  final String name;
  final String sizeLabel;
  final String durationLabel;
  final Gradient gradient;
}

@immutable
class FileItemModel {
  const FileItemModel({
    required this.name,
    required this.ext,
    required this.meta,
  });

  final String name;
  final String ext;
  final String meta;
}

@immutable
class TransferGroupModel {
  const TransferGroupModel({
    required this.direction,
    required this.title,
    required this.meta,
    required this.time,
    required this.thumbs,
    required this.moreCount,
    this.record,
  });

  final TransferDirection direction;
  final String title;
  final String meta;
  final String time;
  final List<Gradient> thumbs;
  final int moreCount;

  /// The backing history record (#006) when this row came from real data;
  /// null for placeholder rows. Drives tap-through to the detail page.
  final TransferRecord? record;
}
