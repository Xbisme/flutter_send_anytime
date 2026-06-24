import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/features/home/data/home_placeholder_data_source.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';

/// Loads the Home dashboard (static mock in #001) into the 4-state cubit.
@injectable
class HomeCubit extends AppCubit<HomeDashboard> {
  HomeCubit(this._dataSource);

  final HomePlaceholderDataSource _dataSource;

  /// Load the dashboard.
  Future<void> load() async {
    emitLoading();
    final result = await _dataSource.load();
    result.fold(emitLoaded, emitError);
  }
}
