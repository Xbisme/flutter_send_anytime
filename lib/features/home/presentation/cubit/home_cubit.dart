import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_home_dashboard_usecase.dart';

/// Loads the Home dashboard into the 4-state cubit, reactively (#012, FR-011):
/// it subscribes to the real history-backed dashboard stream and re-emits
/// `loaded` on every change (a new transfer, a deleted record, clear-all), with
/// no parallel data model (the #006 store is the single source of truth).
@injectable
class HomeCubit extends AppCubit<HomeDashboard> {
  HomeCubit(this._watchDashboard);

  final WatchHomeDashboardUseCase _watchDashboard;
  StreamSubscription<HomeDashboard>? _subscription;

  /// Begin streaming the dashboard. Safe to call once on page mount.
  Future<void> load() async {
    emitLoading();
    await _subscription?.cancel();
    _subscription = _watchDashboard().listen(
      emitLoaded,
      onError: (Object error, StackTrace _) =>
          emitError(AppFailure.unexpected(error: error)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
