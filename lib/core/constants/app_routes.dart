/// Centralized route paths. Never hardcode path strings (Constitution X).
abstract final class AppRoutes {
  static const splash = '/';
  static const home = '/home';
  static const history = '/history';
  static const settings = '/settings';
  static const send = '/send';
  static const receive = '/receive';

  /// Shared pairing hub (#004) — reused by Send and Receive (#005). Returns a
  /// `ConnectResult` (the open data transport) to its caller.
  static const connect = '/connect';

  /// Send progress + completion screen (#004), driven by the transfer stream.
  static const sendProgress = '/send/progress';

  /// Receive progress + completion screen (#005), driven by the transfer
  /// stream; reuses the shared Connect hub (receiver role) for code entry.
  static const receiveProgress = '/receive/progress';

  /// Dev-flavor-only signaling/pairing debug surface (#003, FR-021a). Mounted
  /// only when `AppConfig.flavor.isDev`; absent from prod builds.
  static const pairingDebug = '/dev/pairing';

  /// Reserved deep-link scheme (no handlers wired in #001).
  static const deepLinkScheme = 'safesend';
}
