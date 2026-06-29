import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/data/home_dashboard_builder.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Streams all transferred items of one [MediaCategory] for the See-all screen
/// (#012, FR-009) — uncapped, newest-first, from the shared history store.
@injectable
class WatchMediaItemsUseCase {
  const WatchMediaItemsUseCase(this._repository);

  final TransferHistoryRepository _repository;

  /// Emits the full category list for each history snapshot.
  Stream<List<MediaItem>> call(MediaCategory category) => _repository
      .watch(HistoryFilter.none)
      .map((records) => HomeDashboardBuilder.mediaItems(records, category));
}
