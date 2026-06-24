import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart';

void main() {
  group('HomeCubit', () {
    test('initial state is AppInitial', () {
      expect(
        HomeCubit(HomePlaceholderDataSource()).state,
        isA<AppInitial<HomeDashboard>>(),
      );
    });

    blocTest<HomeCubit, AppState<HomeDashboard>>(
      'emits [loading, loaded] with the mock dashboard on load()',
      build: () => HomeCubit(HomePlaceholderDataSource()),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<AppLoading<HomeDashboard>>(),
        isA<AppLoaded<HomeDashboard>>(),
      ],
    );

    test('loaded dashboard carries the sample sections', () async {
      final cubit = HomeCubit(HomePlaceholderDataSource());
      await cubit.load();
      final state = cubit.state;
      expect(state, isA<AppLoaded<HomeDashboard>>());
      final data = (state as AppLoaded<HomeDashboard>).data;
      expect(data.stats, hasLength(3));
      expect(data.recentImages, isNotEmpty);
      expect(data.recentTransfers, isNotEmpty);
      await cubit.close();
    });
  });
}
