import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

part 'history_filter.freezed.dart';

/// The active browse state applied over history records (#006). [from]/[to] are
/// an inclusive local-day range; [query] matches a record's peer label or any
/// of its file names (case-insensitive).
@freezed
abstract class HistoryFilter with _$HistoryFilter {
  const factory HistoryFilter({
    TransferDirection? direction,
    DateTime? from,
    DateTime? to,
    String? query,
  }) = _HistoryFilter;

  const HistoryFilter._();

  /// The default, unfiltered view (full list).
  static const HistoryFilter none = HistoryFilter();

  /// Whether any narrowing is applied — drives the "no results" vs never-had-
  /// history empty state (FR-019).
  bool get isActive =>
      direction != null ||
      from != null ||
      to != null ||
      (query != null && query!.trim().isNotEmpty);

  /// Trimmed, non-empty query, or null.
  String? get normalizedQuery {
    final q = query?.trim();
    return (q == null || q.isEmpty) ? null : q;
  }
}
