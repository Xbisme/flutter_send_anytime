import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_recent_transfers_usecase.dart';
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart';

class _MockWatchRecent extends Mock implements WatchRecentTransfersUseCase {}

TransferRecord _record(String id) => TransferRecord(
  id: id,
  direction: TransferDirection.sent,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 1,
  totalBytes: 100,
  createdAt: DateTime(2026, 6, 25),
  files: const [RecordedFile(name: 'a.pdf', size: 100)],
);

void main() {
  late _MockWatchRecent watchRecent;

  setUp(() {
    watchRecent = _MockWatchRecent();
    when(
      () => watchRecent(limit: any(named: 'limit')),
    ).thenAnswer((_) => Stream.value([_record('a')]));
  });

  HomeCubit build() => HomeCubit(HomePlaceholderDataSource(), watchRecent);

  group('HomeCubit', () {
    test('initial state is AppInitial', () {
      expect(build().state, isA<AppInitial<HomeDashboard>>());
    });

    blocTest<HomeCubit, AppState<HomeDashboard>>(
      'emits [loading, loaded] with the dashboard on load()',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AppLoading<HomeDashboard>>(),
        isA<AppLoaded<HomeDashboard>>(),
      ],
    );

    test(
      'recent transfers are backfilled from real history (FR-026)',
      () async {
        final cubit = build();
        await cubit.load();
        final data = (cubit.state as AppLoaded<HomeDashboard>).data;
        expect(data.stats, hasLength(3)); // placeholder sections preserved
        expect(data.recentTransfers, hasLength(1));
        expect(data.recentTransfers.first.record?.id, 'a');
        await cubit.close();
      },
    );

    test('empty history yields an empty recent section (FR-027)', () async {
      when(
        () => watchRecent(limit: any(named: 'limit')),
      ).thenAnswer((_) => Stream.value(const []));
      final cubit = build();
      await cubit.load();
      final data = (cubit.state as AppLoaded<HomeDashboard>).data;
      expect(data.recentTransfers, isEmpty);
      await cubit.close();
    });
  });
}
