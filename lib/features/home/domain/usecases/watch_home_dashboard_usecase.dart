import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/features/home/data/home_dashboard_builder.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Streams the real Home dashboard, rebuilt on every history change (#012,
/// FR-011), from the shared transfer-history store (#006).
@injectable
class WatchHomeDashboardUseCase {
  const WatchHomeDashboardUseCase(this._repository);

  final TransferHistoryRepository _repository;

  /// Emits a fresh [HomeDashboard] for each history snapshot. `now` is read at
  /// map time (the impure boundary) and passed into the pure builder.
  Stream<HomeDashboard> call() => _repository
      .watch(HistoryFilter.none)
      .map(
        (records) => HomeDashboardBuilder.build(records, now: DateTime.now()),
      );
}
