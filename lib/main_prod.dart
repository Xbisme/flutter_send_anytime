import 'package:safe_send/bootstrap.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';

/// Public STUN servers (Google) — free, sufficient for the common NAT case.
/// A documented TURN fallback hook can be added to this list later (#011); it
/// is never backed by a running relay here (Constitution I).
const _stunServers = <RtcIceServer>[
  RtcIceServer(urls: ['stun:stun.l.google.com:19302']),
  RtcIceServer(urls: ['stun:stun1.l.google.com:19302']),
];

Future<void> main() => bootstrap(
  AppConfig(
    flavor: AppFlavor.prod,
    iceServers: _stunServers,
    // TLS-only in prod. Placeholder host — replace when the relay is deployed
    // (#011); endpoint is configurable per flavor (Constitution VIII).
    signalingEndpoint: Uri.parse('wss://signal.safesend.app'),
  ),
);
