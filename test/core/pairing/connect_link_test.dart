import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/domain/result.dart';

void main() {
  group('ConnectLink.build', () {
    test('builds the canonical URI for a valid code', () {
      expect(ConnectLink.build('042815'), 'safesend://connect?v=1&code=042815');
    });

    test('round-trips through parse', () {
      final uri = ConnectLink.build('999000');
      final result = ConnectLink.parse(uri);
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).value, '999000');
    });
  });

  group('ConnectLink.parse — accepts', () {
    test('canonical URI → code', () {
      final r = ConnectLink.parse('safesend://connect?v=1&code=042815');
      expect((r as Success<String>).value, '042815');
    });

    test('tolerates surrounding whitespace', () {
      final r = ConnectLink.parse('  safesend://connect?v=1&code=123456  ');
      expect((r as Success<String>).value, '123456');
    });
  });

  group('ConnectLink.parse — rejects (invalidCode)', () {
    void expectInvalid(String raw) {
      final r = ConnectLink.parse(raw);
      expect(r, isA<Failure<String>>(), reason: raw);
      expect(
        (r as Failure<String>).failure,
        const AppFailure.invalidCode(),
        reason: raw,
      );
    }

    test(
      '5-digit code',
      () => expectInvalid('safesend://connect?v=1&code=4281'),
    );
    test(
      'non-numeric code',
      () => expectInvalid('safesend://connect?v=1&code=abcdef'),
    );
    test(
      'unknown version',
      () => expectInvalid('safesend://connect?v=2&code=042815'),
    );
    test(
      'missing version',
      () => expectInvalid('safesend://connect?code=042815'),
    );
    test('missing code', () => expectInvalid('safesend://connect?v=1'));
    test(
      'wrong scheme',
      () => expectInvalid('https://example.com/?v=1&code=042815'),
    );
    test(
      'wrong target',
      () => expectInvalid('safesend://send?v=1&code=042815'),
    );
    test('foreign QR (wifi)', () => expectInvalid('WIFI:S:net;T:WPA;P:pw;;'));
    test('arbitrary text', () => expectInvalid('just some text'));
    test('empty', () => expectInvalid(''));
  });
}
