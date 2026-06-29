import 'package:flutter/widgets.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/utils/file_category.dart';

/// Aggregate of all Home dashboard data, built from real transfer history
/// (#012; replaces the #001/#006 placeholder). Immutable presentation
/// view-model.
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

  /// An all-zero dashboard (fresh install / no history — FR-010).
  static const empty = HomeDashboard(
    summary: TransferSummary.zero,
    stats: [
      StatTileModel(category: MediaCategory.photos, count: 0),
      StatTileModel(category: MediaCategory.videos, count: 0),
      StatTileModel(category: MediaCategory.files, count: 0),
    ],
    recentImages: [],
    recentVideos: [],
    recentFiles: [],
    recentTransfers: [],
  );

  final TransferSummary summary;
  final List<StatTileModel> stats;
  final List<MediaItem> recentImages;
  final List<MediaItem> recentVideos;
  final List<MediaItem> recentFiles;
  final List<TransferGroupModel> recentTransfers;
}

/// Hero summary totals (#012, FR-001/002/003).
@immutable
class TransferSummary {
  const TransferSummary({
    required this.sentBytes,
    required this.receivedBytes,
    required this.monthlyTransferCount,
    required this.progressFraction,
  });

  static const zero = TransferSummary(
    sentBytes: 0,
    receivedBytes: 0,
    monthlyTransferCount: 0,
    progressFraction: 0,
  );

  final int sentBytes;
  final int receivedBytes;
  final int monthlyTransferCount;
  final double progressFraction;
}

/// One stat tile: a category and its real transferred-file count (#012,
/// FR-004). Tint + icon + label are resolved in the presentation layer from
/// design tokens (Constitution VI).
@immutable
class StatTileModel {
  const StatTileModel({required this.category, required this.count});

  final MediaCategory category;
  final int count;
}

/// A single transferred media item shown on Home or a See-all screen (#012).
/// Unified across the photo/video/file sections; backs both surfaces.
@immutable
class MediaItem {
  const MediaItem({
    required this.category,
    required this.name,
    required this.sizeLabel,
    required this.record,
    this.ext = '',
    this.localPath,
    this.durationLabel,
  });

  final MediaCategory category;
  final String name;

  /// Mono-formatted file size (e.g. `2.4 MB`).
  final String sizeLabel;

  /// Upper-case extension (no dot), for the file chip / icon fallback.
  final String ext;

  /// The backing history record (#006) — drives tap-through to its detail.
  final TransferRecord record;

  /// The file's on-disk path when available + readable (received files) →
  /// drives a real image thumbnail; null → type-icon fallback (FR-006a).
  final String? localPath;

  /// Video duration label when known; null otherwise (history stores no
  /// duration, so this is null today — FR-006 "where known").
  final String? durationLabel;
}

@immutable
class TransferGroupModel {
  const TransferGroupModel({
    required this.direction,
    required this.title,
    required this.meta,
    required this.time,
    this.record,
  });

  final TransferDirection direction;
  final String title;
  final String meta;
  final String time;

  /// The backing history record (#006) when this row came from real data;
  /// null for placeholder rows. Drives tap-through to the detail page.
  final TransferRecord? record;
}
