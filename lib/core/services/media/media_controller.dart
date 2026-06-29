import 'package:flutter/widgets.dart';

/// A snapshot of media playback progress (#013). Streamed by [MediaController]
/// so `MediaPlayerCubit` projects it without touching the platform plugin.
@immutable
class MediaProgress {
  const MediaProgress({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });

  static const zero = MediaProgress(
    position: Duration.zero,
    duration: Duration.zero,
    isPlaying: false,
  );

  final Duration position;
  final Duration duration;
  final bool isPlaying;
}

/// Thin seam over the underlying video/audio player (#013, FR-006). Abstracted
/// so `MediaPlayerCubit` is unit/bloc-testable with a fake (the platform plugin
/// is exercised only on a device — mirrors the #002/#011 seams).
abstract class MediaController {
  /// Load the file and prepare for playback; throws on a fatal decode error.
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();

  /// Progress updates (position/duration/playing).
  Stream<MediaProgress> get progress;

  /// True if the file failed to load / decode.
  bool get hasError;

  /// Video aspect ratio, or `0` when there is no video track (audio-only).
  double get aspectRatio;

  /// Whether the file has no video track → the audio-only layout (FR-007).
  bool get isAudioOnly => aspectRatio <= 0;

  /// The video render surface (impl returns the plugin's view; a fake returns a
  /// placeholder). Only used when [isAudioOnly] is false.
  Widget videoView();
}

/// Creates a [MediaController] for a file path. Injected so the cubit stays
/// decoupled from the concrete `video_player` implementation (testability).
// ignore: one_member_abstracts
abstract class MediaControllerFactory {
  MediaController create(String path);
}
