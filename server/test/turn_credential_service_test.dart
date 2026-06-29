import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:safesend_signaling/safesend_signaling.dart';
import 'package:server/turn_credential_service.dart';
import 'package:test/test.dart';

void main() {
  group('TurnCredentialService.mint', () {
    final svc = TurnCredentialService(
      urls: ['turn:turn.example:3478?transport=udp'],
      secret: 'top-secret',
    );
    final now = DateTime.utc(2026, 1, 1, 12);

    test('username is the Unix expiry timestamp', () {
      final frame = svc.mint(now);
      final expectedExpiry =
          (now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/ 1000)
              .toString();
      expect(frame.username, expectedExpiry);
      expect(frame.ttlSeconds, 600);
      expect(frame.urls, ['turn:turn.example:3478?transport=udp']);
    });

    test(
      'credential is base64(HMAC-SHA1(secret, username)) — deterministic',
      () {
        final frame = svc.mint(now);
        final expectedHmac = base64.encode(
          Hmac(
            sha1,
            utf8.encode('top-secret'),
          ).convert(utf8.encode(frame.username)).bytes,
        );
        expect(frame.credential, expectedHmac);
        // Same inputs → identical credential (no randomness).
        expect(svc.mint(now).credential, frame.credential);
      },
    );

    test('later now → later expiry → different credential', () {
      final a = svc.mint(now);
      final b = svc.mint(now.add(const Duration(seconds: 30)));
      expect(b.username, isNot(a.username));
      expect(b.credential, isNot(a.credential));
    });

    test('the frame never carries the secret', () {
      final json = svc.mint(now).toJson().toString();
      expect(json.contains('top-secret'), isFalse);
    });
  });

  group('TurnCredentialService.fromEnv', () {
    test('null when TURN_URLS or TURN_SECRET missing/empty', () {
      expect(TurnCredentialService.fromEnv({}), isNull);
      expect(
        TurnCredentialService.fromEnv({'TURN_URLS': 'turn:x'}),
        isNull,
      );
      expect(
        TurnCredentialService.fromEnv({'TURN_SECRET': 's'}),
        isNull,
      );
      expect(
        TurnCredentialService.fromEnv({'TURN_URLS': '  ', 'TURN_SECRET': 's'}),
        isNull,
      );
    });

    test('parses comma-separated urls + optional ttl', () {
      final svc = TurnCredentialService.fromEnv({
        'TURN_URLS': 'turn:a:3478, turns:a:5349 ',
        'TURN_SECRET': 's',
        'TURN_TTL_SECONDS': '120',
      })!;
      expect(svc.urls, ['turn:a:3478', 'turns:a:5349']);
      expect(svc.ttl, const Duration(seconds: 120));
    });

    test('defaults ttl to 10 minutes when unset/invalid', () {
      final svc = TurnCredentialService.fromEnv({
        'TURN_URLS': 'turn:a',
        'TURN_SECRET': 's',
      })!;
      expect(svc.ttl, const Duration(minutes: 10));
    });

    test('produces a valid decodable frame end-to-end', () {
      final svc = TurnCredentialService.fromEnv({
        'TURN_URLS': 'turn:a:3478',
        'TURN_SECRET': 's',
      })!;
      final encoded = svc.mint(DateTime.utc(2026)).encode();
      final decoded = SignalingFrame.tryDecode(encoded);
      expect(decoded, isA<TurnCredentialsFrame>());
    });
  });
}
