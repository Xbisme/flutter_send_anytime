import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/history/domain/usecases/watch_history_usecase.dart';
import 'package:safe_send/features/history/presentation/cubit/history_cubit.dart';
import 'package:safe_send/features/history/presentation/cubit/history_view.dart';

class _MockWatchHistory extends Mock implements WatchHistoryUseCase {}

TransferRecord _record(String id, DateTime at) => TransferRecord(
  id: id,
  direction: TransferDirection.sent,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 1,
  totalBytes: 100,
  createdAt: at,
);

void main() {
  late _MockWatchHistory watch;
  late StreamController<List<TransferRecord>> controller;

  setUpAll(() {
    registerFallbackValue(HistoryFilter.none);
  });

  setUp(() {
    watch = _MockWatchHistory();
    controller = StreamController<List<TransferRecord>>.broadcast();
    when(() => watch(any())).thenAnswer((_) => controller.stream);
  });

  tearDown(() => controller.close());

  test('initial state is AppInitial', () {
    expect(HistoryCubit(watch).state, isA<AppInitial<HistoryView>>());
  });

  blocTest<HistoryCubit, AppState<HistoryView>>(
    'emits [loading, loaded] grouped by day, newest-first',
    build: () => HistoryCubit(watch),
    act: (cubit) async {
      cubit.load();
      controller.add([
        _record('today-late', DateTime(2026, 6, 25, 16)),
        _record('today-early', DateTime(2026, 6, 25, 9)),
        _record('yesterday', DateTime(2026, 6, 24, 11)),
      ]);
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<HistoryView>>(),
      isA<AppLoaded<HistoryView>>()
          .having((s) => s.data.sections.length, 'day sections', 2)
          .having(
            (s) => s.data.sections.first.records.map((r) => r.id).toList(),
            'first day records newest-first',
            ['today-late', 'today-early'],
          )
          .having((s) => s.data.filterActive, 'filterActive', false),
    ],
  );

  blocTest<HistoryCubit, AppState<HistoryView>>(
    'an empty record list is a loaded-empty view (not an error)',
    build: () => HistoryCubit(watch),
    act: (cubit) async {
      cubit.load();
      controller.add(const []);
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<HistoryView>>(),
      isA<AppLoaded<HistoryView>>()
          .having((s) => s.data.isEmpty, 'isEmpty', true)
          .having((s) => s.data.filterActive, 'filterActive', false),
    ],
  );

  test('setDirection re-queries with the chosen direction', () async {
    final cubit = HistoryCubit(watch)
      ..load()
      ..setDirection(TransferDirection.received);
    await pumpEventQueue();
    final lastFilter =
        verify(() => watch(captureAny())).captured.last as HistoryFilter;
    expect(lastFilter.direction, TransferDirection.received);
    expect(cubit.isFilterActive, isTrue);
    await cubit.close();
  });

  test('setQuery then clearFilters toggles the active flag', () async {
    final cubit = HistoryCubit(watch)
      ..load()
      ..setQuery('report');
    expect(cubit.isFilterActive, isTrue);
    cubit.clearFilters();
    expect(cubit.isFilterActive, isFalse);
    await pumpEventQueue();
    await cubit.close();
  });

  blocTest<HistoryCubit, AppState<HistoryView>>(
    'an empty result under an active filter is a no-results view',
    build: () => HistoryCubit(watch),
    act: (cubit) async {
      cubit
        ..load()
        ..setQuery('zzz');
      controller.add(const []);
      await pumpEventQueue();
    },
    verify: (_) {},
    expect: () => contains(
      isA<AppLoaded<HistoryView>>()
          .having((s) => s.data.isEmpty, 'isEmpty', true)
          .having((s) => s.data.filterActive, 'filterActive', true),
    ),
  );
}
