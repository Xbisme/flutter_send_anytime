import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_home_dashboard_usecase.dart';
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart';

class _MockWatch extends Mock implements WatchHomeDashboardUseCase {}

HomeDashboard _dash(int monthly) => HomeDashboard(
  summary: TransferSummary(
    sentBytes: 0,
    receivedBytes: 0,
    monthlyTransferCount: monthly,
    progressFraction: 0,
  ),
  stats: HomeDashboard.empty.stats,
  recentImages: const [],
  recentVideos: const [],
  recentFiles: const [],
  recentTransfers: const [],
);

void main() {
  late _MockWatch watch;

  setUp(() => watch = _MockWatch());

  HomeCubit build() => HomeCubit(watch);

  group('HomeCubit', () {
    test('initial state is AppInitial', () {
      when(() => watch()).thenAnswer((_) => const Stream.empty());
      expect(build().state, isA<AppInitial<HomeDashboard>>());
    });

    blocTest<HomeCubit, AppState<HomeDashboard>>(
      'emits [loading, loaded] on the first dashboard snapshot',
      build: () {
        when(() => watch()).thenAnswer((_) => Stream.value(_dash(3)));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AppLoading<HomeDashboard>>(),
        isA<AppLoaded<HomeDashboard>>().having(
          (s) => s.data.summary.monthlyTransferCount,
          'monthly',
          3,
        ),
      ],
    );

    test(
      'each snapshot drives a fresh loaded state (live update, FR-011)',
      () async {
        final controller = StreamController<HomeDashboard>();
        when(() => watch()).thenAnswer((_) => controller.stream);
        final cubit = build();
        await cubit.load();
        controller
          ..add(_dash(1))
          ..add(_dash(2));
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state, isA<AppLoaded<HomeDashboard>>());
        expect(
          (cubit.state as AppLoaded<HomeDashboard>)
              .data
              .summary
              .monthlyTransferCount,
          2,
        );
        await controller.close();
        await cubit.close();
      },
    );

    blocTest<HomeCubit, AppState<HomeDashboard>>(
      'emits error when the dashboard stream errors',
      build: () {
        when(
          () => watch(),
        ).thenAnswer((_) => Stream.error(Exception('boom')));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AppLoading<HomeDashboard>>(),
        isA<AppError<HomeDashboard>>(),
      ],
    );
  });
}
