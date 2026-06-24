/// Centralized route paths. Never hardcode path strings (Constitution X).
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const history = '/history';
  static const settings = '/settings';
  static const send = '/send';
  static const receive = '/receive';

  /// Dev-flavor-only signaling/pairing debug surface (#003, FR-021a). Mounted
  /// only when `AppConfig.flavor.isDev`; absent from prod builds.
  static const pairingDebug = '/dev/pairing';

  /// Reserved deep-link scheme (no handlers wired in #001).
  static const deepLinkScheme = 'safesend';
}
