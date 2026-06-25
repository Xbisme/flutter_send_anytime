import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/features/home/data/home_history_data_source.dart';
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_recent_transfers_usecase.dart';

/// Loads the Home dashboard into the 4-state cubit. The hero/stat/media
/// sections are still placeholder (#001); the **recent transfers** section is
/// now backfilled from real history (#006, FR-026) via the shared store, with
/// no change to the [HomeDashboard] contract (the #001 FR-008 seam).
@injectable
class HomeCubit extends AppCubit<HomeDashboard> {
  HomeCubit(this._dataSource, this._watchRecent);

  final HomePlaceholderDataSource _dataSource;
  final WatchRecentTransfersUseCase _watchRecent;

  /// Load the dashboard, merging real recent transfers over the placeholder.
  Future<void> load() async {
    emitLoading();
    final result = await _dataSource.load();
    await result.fold(
      (dashboard) async {
        final records = await _watchRecent().first;
        emitLoaded(
          HomeHistoryMapper.withRecent(
            dashboard,
            HomeHistoryMapper.recent(records),
          ),
        );
      },
      (failure) async => emitError(failure),
    );
  }
}
