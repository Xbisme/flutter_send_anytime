import 'package:flutter/foundation.dart';
import 'package:safe_send/core/utils/formatters.dart';

/// Display-ready projection of media playback (#013, US2). Backs
/// `AppCubit<MediaPlaybackView>`; time labels use mono clock formatting.
@immutable
class MediaPlaybackView {
  const MediaPlaybackView({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isAudioOnly,
    required this.aspectRatio,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isAudioOnly;
  final double aspectRatio;

  /// Elapsed time, e.g. `1:05`.
  String get elapsedLabel => Formatters.clock(position);

  /// Total duration, e.g. `3:42`.
  String get totalLabel => Formatters.clock(duration);

  /// Scrubber fraction in `[0, 1]`.
  double get progressFraction {
    final total = duration.inMilliseconds;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}
