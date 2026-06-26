import 'dart:io';
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
    flavor: AppFlavor.dev,
    iceServers: _stunServers,
    // Cleartext ws:// for local testing.
    //  • iOS simulator   → ws://localhost:8080   (ATS exempts localhost)
    //  • Android emulator → ws://10.0.2.2:8080    (host alias)
    //  • Real Android device → ws://192.168.1.16:8080  (Mac LAN IP — device must
    //    be on the same Wi-Fi; 10.0.2.2 only resolves inside the emulator)
    //  • Two real devices → ws://<Mac-LAN-IP>:8080 + iOS ATS cleartext exception
    //                        (deferred #003 task — non-localhost ws:// is ATS-blocked)
    signalingEndpoint: Uri.parse(
      Platform.isIOS ? 'ws://192.168.1.137:8080' : 'ws://192.168.1.16:8080',
    ),
  ),
);
