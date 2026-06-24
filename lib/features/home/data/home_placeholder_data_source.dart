import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Provides static sample/mock dashboard data matching the design (FR-008).
///
/// #006 replaces this with a real (drift-backed) source without changing the
/// [HomeDashboard] contract or the cubit/UI.
@lazySingleton
class HomePlaceholderDataSource {
  static const _g1 = LinearGradient(
    colors: [Color(0xFFFBA24B), Color(0xFFF2682C)],
  );
  static const _g2 = LinearGradient(
    colors: [Color(0xFF7FB0E6), Color(0xFF3B6FB0)],
  );
  static const _g3 = LinearGradient(
    colors: [Color(0xFF5B6B64), Color(0xFF18211D)],
  );
  static const _g4 = LinearGradient(
    colors: [Color(0xFF1ED66E), Color(0xFF06632D)],
  );
  static const _g5 = LinearGradient(
    colors: [Color(0xFFF5C77E), Color(0xFFD88A3A)],
  );
  static const _g6 = LinearGradient(
    colors: [Color(0xFF16D8C0), Color(0xFF009E8A)],
  );
  static const _g7 = LinearGradient(
    colors: [Color(0xFFB06AF9), Color(0xFF7C3AED)],
  );

  /// Load the static dashboard. Always succeeds in #001.
  Future<Result<HomeDashboard>> load() async {
    const dashboard = HomeDashboard(
      summary: TransferSummary(
        sentBytes: 26092811878, // ~24.3 GB
        receivedBytes: 42634843750, // ~39.7 GB
        monthlyTransferCount: 128,
        progressFraction: 0.62,
      ),
      stats: [
        StatTileModel(kind: StatKind.photos, count: 1247, tint: AppColors.info),
        StatTileModel(
          kind: StatKind.videos,
          count: 342,
          tint: Color(0xFF009E8A),
        ),
        StatTileModel(
          kind: StatKind.files,
          count: 856,
          tint: Color(0xFFD98E0A),
        ),
      ],
      recentImages: [
        MediaThumb(name: 'Biển.jpg', sizeLabel: '2.4 MB', gradient: _g1),
        MediaThumb(name: 'Núi.jpg', sizeLabel: '3.1 MB', gradient: _g2),
        MediaThumb(name: 'Phố.jpg', sizeLabel: '1.8 MB', gradient: _g3),
        MediaThumb(name: 'Rừng.jpg', sizeLabel: '2.7 MB', gradient: _g4),
        MediaThumb(name: 'Sa mạc.jpg', sizeLabel: '2.2 MB', gradient: _g5),
        MediaThumb(name: 'Đại dương.jpg', sizeLabel: '3.4 MB', gradient: _g6),
      ],
      recentVideos: [
        VideoThumb(
          name: 'Travel_Vlog.mp4',
          sizeLabel: '124.5 MB',
          durationLabel: '4:32',
          gradient: _g2,
        ),
        VideoThumb(
          name: 'Recipe_Tutorial.mp4',
          sizeLabel: '256.8 MB',
          durationLabel: '8:15',
          gradient: _g1,
        ),
        VideoThumb(
          name: 'Workout.mp4',
          sizeLabel: '342.1 MB',
          durationLabel: '12:45',
          gradient: _g7,
        ),
        VideoThumb(
          name: 'Drone_Footage.mp4',
          sizeLabel: '198.4 MB',
          durationLabel: '6:22',
          gradient: _g6,
        ),
      ],
      recentFiles: [
        FileItemModel(
          name: 'Project_Proposal.pdf',
          ext: 'PDF',
          meta: '4.2 MB · Hôm nay, 14:34',
        ),
        FileItemModel(
          name: 'Meeting_Notes.docx',
          ext: 'DOCX',
          meta: '1.8 MB · Hôm qua',
        ),
        FileItemModel(
          name: 'Budget_2026.xlsx',
          ext: 'XLSX',
          meta: '3.5 MB · 15 Th6',
        ),
        FileItemModel(
          name: 'Presentation_Deck.pptx',
          ext: 'PPTX',
          meta: '12.7 MB · 12 Th6',
        ),
      ],
      recentTransfers: [
        TransferGroupModel(
          direction: TransferDirection.sent,
          title: 'Gửi tới iPhone 14 Pro',
          meta: '5 files · 24.8 MB',
          time: '2 giờ trước',
          thumbs: [_g3, _g2, _g1],
          moreCount: 2,
        ),
        TransferGroupModel(
          direction: TransferDirection.received,
          title: 'Nhận từ MacBook',
          meta: '8 files · 156.2 MB',
          time: '1 ngày trước',
          thumbs: [_g5, _g6, _g7],
          moreCount: 5,
        ),
      ],
    );
    return const Result.success(dashboard);
  }
}
