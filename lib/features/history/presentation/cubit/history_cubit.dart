import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/history/domain/usecases/watch_history_usecase.dart';
import 'package:safe_send/features/history/presentation/cubit/history_view.dart';

/// Drives the History tab (#006). Subscribes to the repository's reactive
/// stream through [WatchHistoryUseCase], groups records by local day, and holds
/// the active [HistoryFilter] (mutated by search/filter in US4). 4-state
/// (Constitution III): loaded carries a [HistoryView]; an empty list is a
/// loaded view with no sections (not an error).
@injectable
class HistoryCubit extends AppCubit<HistoryView> {
  HistoryCubit(this._watchHistory);

  final WatchHistoryUseCase _watchHistory;

  HistoryFilter _filter = HistoryFilter.none;
  StreamSubscription<List<TransferRecord>>? _sub;

  /// The current filter (drives search/filter UI state).
  HistoryFilter get filter => _filter;

  /// Begin watching history (call once when the page mounts).
  void load() {
    emitLoading();
    _resubscribe();
  }

  /// Replace the active [HistoryFilter] and re-query (US4).
  void applyFilter(HistoryFilter filter) {
    _filter = filter;
    _resubscribe();
  }

  /// Set the text query (peer label / file names), keeping other filters.
  void setQuery(String? query) => applyFilter(
    HistoryFilter(
      direction: _filter.direction,
      from: _filter.from,
      to: _filter.to,
      query: query,
    ),
  );

  /// Set the direction filter (null = both), keeping other filters.
  void setDirection(TransferDirection? direction) => applyFilter(
    HistoryFilter(
      direction: direction,
      from: _filter.from,
      to: _filter.to,
      query: _filter.query,
    ),
  );

  /// Set the inclusive local-day range (null = unbounded), keeping the rest.
  void setDateRange(DateTime? from, DateTime? to) => applyFilter(
    HistoryFilter(
      direction: _filter.direction,
      from: from,
      to: to,
      query: _filter.query,
    ),
  );

  /// Clear all filters back to the full list.
  void clearFilters() => applyFilter(HistoryFilter.none);

  /// Whether any filter/search is active.
  bool get isFilterActive => _filter.isActive;

  void _resubscribe() {
    unawaited(_sub?.cancel());
    _sub = _watchHistory(_filter).listen(
      (records) => emitLoaded(_group(records)),
      onError: (Object _) => emitError(const AppFailure.unexpected()),
    );
  }

  HistoryView _group(List<TransferRecord> records) {
    final byDay = <DateTime, List<TransferRecord>>{};
    for (final r in records) {
      final local = r.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      byDay.putIfAbsent(day, () => []).add(r);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return HistoryView(
      sections: [
        for (final d in days) HistoryDaySection(day: d, records: byDay[d]!),
      ],
      filterActive: _filter.isActive,
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
