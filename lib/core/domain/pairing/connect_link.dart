import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

/// The QR / deep-link payload codec for pairing (#007).
///
/// The 6-digit code is the rendezvous identifier (#003); this only changes how
/// it is *exchanged*. The canonical form `safesend://connect?v=1&code=NNNNNN` is
/// versioned and deep-link-ready so #008 (Share Link) reuses it verbatim. #007
/// only **produces** and **parses** it in-app (camera / photo scan); OS-level
/// deep-link handling is out of scope.
///
/// Carries only `version` + `code` — never file data, paths, or peer identity
/// (Constitution I). Validation reuses [SignalingProtocol.isValidCode] so the
/// 6-digit rule has a single source of truth.
abstract final class ConnectLink {
  /// Current payload version.
  static const int version = 1;

  static const String _scheme = AppRoutes.deepLinkScheme; // 'safesend'
  static const String _target = 'connect';

  /// Build the canonical URI for [code]. [code] MUST be a valid 6-digit code.
  static String build(String code) {
    assert(
      SignalingProtocol.isValidCode(code),
      'ConnectLink.build requires a valid 6-digit code',
    );
    return Uri(
      scheme: _scheme,
      host: _target,
      queryParameters: {'v': '$version', 'code': code},
    ).toString();
  }

  /// Parse [raw] to its pairing code, or [AppFailure.invalidCode] on any
  /// deviation: non-URI, wrong scheme, wrong target, unsupported version, or a
  /// missing/malformed code. Syntactic only — an expired-but-valid code parses
  /// here and is rejected later by the join path.
  static Result<String> parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != _scheme) {
      return const Result.failure(AppFailure.invalidCode());
    }
    // Accept both authority form (`scheme://connect`) and path form
    // (`scheme:connect`); the canonical build uses the authority form.
    final target = uri.host.isNotEmpty ? uri.host : uri.path;
    if (target != _target) {
      return const Result.failure(AppFailure.invalidCode());
    }
    if (uri.queryParameters['v'] != '$version') {
      return const Result.failure(AppFailure.invalidCode());
    }
    final code = uri.queryParameters['code'] ?? '';
    if (!SignalingProtocol.isValidCode(code)) {
      return const Result.failure(AppFailure.invalidCode());
    }
    return Result.success(code);
  }
}
