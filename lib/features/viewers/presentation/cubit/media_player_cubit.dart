import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/services/media/media_controller.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_playback_view.dart';

/// Drives the shared video/audio player (#013, US2) over the [MediaController]
/// seam. Disposes the controller in [close] so playback stops and resources
/// release when the viewer is dismissed (FR-008).
@injectable
class MediaPlayerCubit extends AppCubit<MediaPlaybackView> {
  MediaPlayerCubit(this._factory);

  final MediaControllerFactory _factory;
  MediaController? _controller;
  StreamSubscription<MediaProgress>? _subscription;

  /// The controller backing the video surface (read by the page); null until
  /// [open] succeeds.
  MediaController? get controller => _controller;

  /// Load [path], begin playback, and stream progress.
  Future<void> open(String path) async {
    emitLoading();
    final controller = _factory.create(path);
    _controller = controller;
    try {
      await controller.initialize();
    } on Object {
      emitError(const AppFailure.fileReadFailed());
      return;
    }
    if (controller.hasError) {
      emitError(const AppFailure.fileReadFailed());
      return;
    }
    _subscription = controller.progress.listen(_onProgress);
    await controller.play();
  }

  void _onProgress(MediaProgress p) {
    final controller = _controller;
    if (controller == null) return;
    emitLoaded(
      MediaPlaybackView(
        position: p.position,
        duration: p.duration,
        isPlaying: p.isPlaying,
        isAudioOnly: controller.isAudioOnly,
        aspectRatio: controller.aspectRatio,
      ),
    );
  }

  /// Toggle play/pause based on the latest emitted state.
  Future<void> togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    final current = state;
    final playing =
        current is AppLoaded<MediaPlaybackView> && current.data.isPlaying;
    await (playing ? controller.pause() : controller.play());
  }

  /// Seek to [position].
  Future<void> seek(Duration position) =>
      _controller?.seek(position) ?? Future.value();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _controller?.dispose();
    return super.close();
  }
}
