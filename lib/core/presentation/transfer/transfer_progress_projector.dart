import 'package:safe_send/core/domain/transfer/transfer_state.dart';

/// Derives a smoothed transfer speed + ETA across consecutive snapshots. Shared
/// by the Send (#004) and Receive (#005) progress cubits so the timing math
/// lives in one place (analyze U1). Not authoritative — purely presentational.
class TransferProgressProjector {
  final Stopwatch _stopwatch = Stopwatch();
  int _lastBytes = 0;
  Duration _lastElapsed = Duration.zero;
  double _speed = 0;

  /// Elapsed time since [start].
  Duration get elapsed => _stopwatch.elapsed;

  /// The current exponentially-smoothed speed in bytes/second.
  double get speedBytesPerSec => _speed;

  /// Begin (or restart) timing.
  void start() {
    _stopwatch
      ..reset()
      ..start();
    _lastBytes = 0;
    _lastElapsed = Duration.zero;
    _speed = 0;
  }

  /// Fold [snapshot] into the running speed estimate; returns the ETA in whole
  /// seconds, or null when it cannot be estimated yet.
  int? update(TransferSnapshot snapshot) {
    final elapsed = _stopwatch.elapsed;
    final dtMs = (elapsed - _lastElapsed).inMilliseconds;
    if (dtMs > 0) {
      final deltaBytes = snapshot.progress.overallBytesTransferred - _lastBytes;
      final instant = deltaBytes / (dtMs / 1000.0);
      // Exponential smoothing keeps the readout from jumping.
      _speed = _speed == 0 ? instant : _speed * 0.6 + instant * 0.4;
      _lastBytes = snapshot.progress.overallBytesTransferred;
      _lastElapsed = elapsed;
    }
    final remaining =
        snapshot.progress.overallTotalBytes -
        snapshot.progress.overallBytesTransferred;
    return _speed > 0 && remaining > 0 ? (remaining / _speed).round() : null;
  }
}
