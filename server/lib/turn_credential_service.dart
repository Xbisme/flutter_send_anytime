import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

/// Mints short-lived TURN credentials for the coturn `use-auth-secret` scheme
/// (#014).
///
/// coturn validates a credential as `base64(HMAC-SHA1(static-auth-secret,
/// username))` where `username` is a Unix expiry timestamp. The relay shares
/// the same secret and issues a fresh credential per pairing, delivered to each
/// peer over the existing signaling channel ([TurnCredentialsFrame]).
///
/// The secret lives only in the relay's environment — it is NEVER sent to a
/// client and MUST NEVER be logged (Constitution I). When no TURN is
/// configured, the relay simply omits the frame and clients fall back to their
/// static per-flavor ICE config (backward compatible, FR-008).
class TurnCredentialService {
  TurnCredentialService({
    required this.urls,
    required String secret,
    this.ttl = const Duration(minutes: 10),
  }) : _secret = secret;

  /// coturn `turn:`/`turns:` relay endpoints advertised to clients.
  final List<String> urls;

  /// Credential lifetime; clients must (re)connect before it elapses.
  final Duration ttl;

  final String _secret;

  /// Build a fresh credential frame whose username expires at [now] + [ttl].
  /// [now] is a parameter so the HMAC is deterministic under test.
  TurnCredentialsFrame mint(DateTime now) {
    final expiry = (now.add(ttl).millisecondsSinceEpoch ~/ 1000).toString();
    final hmac = Hmac(sha1, utf8.encode(_secret));
    final credential = base64.encode(hmac.convert(utf8.encode(expiry)).bytes);
    return TurnCredentialsFrame(
      urls: List<String>.unmodifiable(urls),
      username: expiry,
      credential: credential,
      ttlSeconds: ttl.inSeconds,
    );
  }

  /// Parse a `TURN_URLS` env value (comma-separated) + `TURN_SECRET` into a
  /// service, or `null` if either is absent/empty (TURN not configured).
  static TurnCredentialService? fromEnv(Map<String, String> env) {
    final rawUrls = env['TURN_URLS']?.trim() ?? '';
    final secret = env['TURN_SECRET']?.trim() ?? '';
    if (rawUrls.isEmpty || secret.isEmpty) return null;
    final urls = rawUrls
        .split(',')
        .map((u) => u.trim())
        .where((u) => u.isNotEmpty)
        .toList();
    if (urls.isEmpty) return null;
    final ttlSeconds = int.tryParse(env['TURN_TTL_SECONDS']?.trim() ?? '');
    return TurnCredentialService(
      urls: urls,
      secret: secret,
      ttl: ttlSeconds != null && ttlSeconds > 0
          ? Duration(seconds: ttlSeconds)
          : const Duration(minutes: 10),
    );
  }
}
