import 'package:safe_send/core/config/app_flavor.dart';

/// A STUN/TURN server descriptor for WebRTC connectivity. Kept free of any
/// plugin types so config stays dependency-light (mapped by the connector).
class RtcIceServer {
  const RtcIceServer({required this.urls, this.username, this.credential});

  /// One or more ICE server URLs (e.g. `stun:...`, `turn:...`).
  final List<String> urls;

  /// Optional TURN username.
  final String? username;

  /// Optional TURN credential.
  final String? credential;
}

/// Immutable per-flavor app configuration, provided at startup by the flavor
/// entry point and registered in the DI container.
class AppConfig {
  const AppConfig({
    required this.flavor,
    this.appName = 'Safe Send',
    this.deepLinkScheme = 'safesend',
    this.iceServers = const <RtcIceServer>[],
    this.signalingEndpoint,
  });

  /// Active build flavor.
  final AppFlavor flavor;

  /// User-facing app name.
  final String appName;

  /// Reserved deep-link scheme (no handlers wired in #001).
  final String deepLinkScheme;

  /// ICE servers used to establish the peer connection. Empty for #002
  /// (loopback needs none); real per-flavor STUN/TURN is wired in #003.
  final List<RtcIceServer> iceServers;

  /// The signaling relay WebSocket endpoint for this flavor (#003). dev uses
  /// `ws://` (localhost/LAN), prod uses `wss://`. Null until set by the flavor
  /// entry point; the signaling client treats null as misconfiguration.
  final Uri? signalingEndpoint;

  /// App Group shared with the iOS Live Activity widget extension (#011), split
  /// per flavor so a dev and a prod build on the same device never share the
  /// transfer-activity container. MUST match the group the native widget reads
  /// (derived there from the flavor-specific bundle id).
  String get liveActivityAppGroupId => flavor.isDev
      ? 'group.app.safesend.dev.liveactivities'
      : 'group.app.safesend.liveactivities';
}
