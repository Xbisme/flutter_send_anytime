import 'package:server/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimiter', () {
    test('allows up to the threshold, then trips', () {
      final limiter = RateLimiter(threshold: 3);
      expect(limiter.registerInvalidJoin(), isFalse); // 1
      expect(limiter.registerInvalidJoin(), isFalse); // 2
      expect(limiter.registerInvalidJoin(), isFalse); // 3 == threshold
      expect(limiter.registerInvalidJoin(), isTrue); // 4 > threshold
      expect(limiter.isLimited, isTrue);
    });

    test('reset clears the count', () {
      final limiter = RateLimiter(threshold: 1)
        ..registerInvalidJoin()
        ..registerInvalidJoin();
      expect(limiter.isLimited, isTrue);
      limiter.reset();
      expect(limiter.isLimited, isFalse);
      expect(limiter.registerInvalidJoin(), isFalse);
    });

    test('window resets the count after it elapses', () {
      var now = DateTime(2026);
      // Default window is 30s.
      final limiter = RateLimiter(threshold: 2, clock: () => now)
        ..registerInvalidJoin()
        ..registerInvalidJoin()
        ..registerInvalidJoin();
      expect(limiter.isLimited, isTrue);

      now = now.add(const Duration(seconds: 31)); // window elapsed
      expect(limiter.registerInvalidJoin(), isFalse); // count restarts
    });

    test('retryAfterSeconds reflects the remaining window', () {
      var now = DateTime(2026);
      // Default window is 30s.
      final limiter = RateLimiter(clock: () => now)..registerInvalidJoin();
      now = now.add(const Duration(seconds: 10));
      expect(limiter.retryAfterSeconds, 20);
    });
  });
}
