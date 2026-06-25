import 'package:flutter/foundation.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';

/// The day-grouped history list the [HistoryView] cubit emits (#006). Records
/// arrive newest-first from the repository; grouping by local calendar day is a
/// presentation concern (timezone-dependent, FR-010).
@immutable
class HistoryView {
  const HistoryView({required this.sections, required this.filterActive});

  /// Day sections, most recent day first.
  final List<HistoryDaySection> sections;

  /// Whether a search/filter is applied — distinguishes the "no results" state
  /// from the never-had-history empty state (FR-019).
  final bool filterActive;

  /// Whether there are no records to show.
  bool get isEmpty => sections.isEmpty;
}

/// One calendar day's worth of records.
@immutable
class HistoryDaySection {
  const HistoryDaySection({required this.day, required this.records});

  /// Local-day bucket (midnight) used to render the section header.
  final DateTime day;

  /// Records on this day, newest-first.
  final List<TransferRecord> records;
}
