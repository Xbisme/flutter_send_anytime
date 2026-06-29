import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_media_items_usecase.dart';

/// Streams every transferred item of one [MediaCategory] for the See-all
/// screen (#012, FR-009), reactively (live-updates with the history store).
@injectable
class SeeAllCubit extends AppCubit<List<MediaItem>> {
  SeeAllCubit(this._watchMedia);

  final WatchMediaItemsUseCase _watchMedia;
  StreamSubscription<List<MediaItem>>? _subscription;

  /// Begin streaming items of [category].
  Future<void> load(MediaCategory category) async {
    emitLoading();
    await _subscription?.cancel();
    _subscription = _watchMedia(category).listen(
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
