/// Per-connection guard against pairing-code enumeration (FR-011a).
///
/// Counts invalid `join` attempts within a sliding [window]. Once more than
/// [threshold] invalid attempts occur in the window, the connection is
/// throttled (`isLimited`) and told to retry later. A valid join [reset]s it.
class RateLimiter {
  RateLimiter({
    this.threshold = 5,
    this.window = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Max invalid joins allowed within [window] before throttling.
  final int threshold;

  /// The sliding window over which invalid joins are counted.
  final Duration window;

  final DateTime Function() _clock;

  int _count = 0;
  DateTime? _windowStart;

  /// Whether the connection is currently throttled.
  bool get isLimited => _count > threshold;

  /// Seconds the client should wait before retrying.
  int get retryAfterSeconds {
    final start = _windowStart;
    if (start == null) return window.inSeconds;
    final elapsed = _clock().difference(start);
    final left = window - elapsed;
    return left.isNegative ? 0 : left.inSeconds;
  }

  /// Record an invalid join attempt. Returns whether the connection is now
  /// throttled.
  bool registerInvalidJoin() {
    final now = _clock();
    final start = _windowStart;
    if (start == null || now.difference(start) > window) {
      _windowStart = now;
      _count = 0;
    }
    _count++;
    return isLimited;
  }

  /// Reset after a valid join.
  void reset() {
    _count = 0;
    _windowStart = null;
  }
}

/// Tuning for the relay's per-connection rate limiting.
class RateLimitConfig {
  const RateLimitConfig({this.threshold = 5, this.window = _defaultWindow});

  static const _defaultWindow = Duration(seconds: 30);

  final int threshold;
  final Duration window;

  /// A fresh limiter using this config.
  RateLimiter build({DateTime Function()? clock}) =>
      RateLimiter(threshold: threshold, window: window, clock: clock);
}
