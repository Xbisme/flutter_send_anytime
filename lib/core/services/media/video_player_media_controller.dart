import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/services/media/media_controller.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:video_player/video_player.dart';

/// [MediaController] backed by `video_player` (#013). The only file that imports
/// `video_player`. AVPlayer/ExoPlayer decode both video and audio; an audio
/// file reports a zero size → [aspectRatio] 0 → the audio-only layout.
class VideoPlayerMediaController implements MediaController {
  VideoPlayerMediaController(this._path);

  final String _path;
  late final VideoPlayerController _controller = VideoPlayerController.file(
    File(_path),
  );
  final StreamController<MediaProgress> _progress =
      StreamController<MediaProgress>.broadcast();
  var _hasError = false;
  Duration _lastPosition = Duration.zero;
  bool? _lastPlaying;

  @override
  Future<void> initialize() async {
    await _configureAudioSessionForPlayback();
    _controller.addListener(_onValue);
    await _controller.initialize();
    _onValue();
  }

  /// flutter_webrtc parks the iOS `AVAudioSession` in a VoIP mode
  /// (`playAndRecord` / `voiceChat`) whose small, low-latency IO buffer makes
  /// `AVPlayer` video stutter — even though the OS player is smooth. Switch the
  /// session to movie playback for the duration of viewing (our data-channel
  /// transfers don't need the VoIP session). iOS-only; best-effort.
  Future<void> _configureAudioSessionForPlayback() async {
    if (!Platform.isIOS) return;
    try {
      await Helper.setAppleAudioConfiguration(
        AppleAudioConfiguration(
          appleAudioCategory: AppleAudioCategory.playback,
          appleAudioMode: AppleAudioMode.moviePlayback,
        ),
      );
    } on Object catch (error) {
      AppLogger.warning('audio session config failed (${error.runtimeType})');
    }
  }

  void _onValue() {
    final v = _controller.value;
    if (v.hasError) _hasError = true;
    if (_progress.isClosed) return;
    // video_player's listener can fire ~per frame; throttle position updates to
    // ~5/s (emit immediately on a play/pause change) so the controls don't
    // rebuild 60×/s. The video Texture renders independently of this stream.
    final playingChanged = v.isPlaying != _lastPlaying;
    final movedEnough =
        (v.position - _lastPosition).abs() >= const Duration(milliseconds: 200);
    if (!playingChanged && !movedEnough) return;
    _lastPlaying = v.isPlaying;
    _lastPosition = v.position;
    _progress.add(
      MediaProgress(
        position: v.position,
        duration: v.duration,
        isPlaying: v.isPlaying,
      ),
    );
  }

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();

  @override
  Future<void> seek(Duration position) => _controller.seekTo(position);

  @override
  Future<void> dispose() async {
    _controller.removeListener(_onValue);
    await _progress.close();
    await _controller.dispose();
  }

  @override
  Stream<MediaProgress> get progress => _progress.stream;

  @override
  bool get hasError => _hasError;

  @override
  double get aspectRatio {
    final size = _controller.value.size;
    if (size.width <= 0 || size.height <= 0) return 0;
    return size.width / size.height;
  }

  @override
  bool get isAudioOnly => aspectRatio <= 0;

  @override
  Widget videoView() => VideoPlayer(_controller);
}

/// Default [MediaControllerFactory] producing `video_player`-backed
/// controllers.
@LazySingleton(as: MediaControllerFactory)
class VideoPlayerMediaControllerFactory implements MediaControllerFactory {
  @override
  MediaController create(String path) => VideoPlayerMediaController(path);
}
