import 'dart:convert';
import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/constants/nearby_constants.dart';
import 'package:safesend_signaling/safesend_signaling.dart';

part 'nearby_device.freezed.dart';

/// A Safe Send device currently advertising on the local network, as seen by a
/// browsing receiver (#009). Ephemeral runtime state — never persisted.
///
/// Carries only what the radar needs: a stable per-advertisement [id], a
/// human-recognizable [displayName], the 6-digit #003 [code] (read from the TXT
/// record and validated), and [lastSeen] freshness. The code is the rendezvous
/// identifier (#003) — the radar only transports it.
@freezed
abstract class NearbyDevice with _$NearbyDevice {
  const factory NearbyDevice({
    required String id,
    required String displayName,
    required String code,
    required DateTime lastSeen,
  }) = _NearbyDevice;

  const NearbyDevice._();

  /// Build the TXT record advertised for [code] (version + code, nothing else —
  /// Constitution I).
  static Map<String, Uint8List?> toTxt({required String code}) => {
    kNearbyTxtVersionKey: Uint8List.fromList(utf8.encode(kNearbyTxtVersion)),
    kNearbyTxtCodeKey: Uint8List.fromList(utf8.encode(code)),
  };

  /// Extract + validate the rendezvous code from a discovered service's TXT
  /// records. Returns null on any deviation: missing/unsupported version, or a
  /// missing/invalid 6-digit code (reuses [SignalingProtocol.isValidCode] so the
  /// rule has one source of truth). Boundary input validation (Constitution I).
  static String? codeFromTxt(Map<String, Uint8List?>? txt) {
    if (txt == null) return null;
    if (_decode(txt[kNearbyTxtVersionKey]) != kNearbyTxtVersion) return null;
    final code = _decode(txt[kNearbyTxtCodeKey]);
    if (code == null || !SignalingProtocol.isValidCode(code)) return null;
    return code;
  }

  static String? _decode(Uint8List? bytes) {
    if (bytes == null) return null;
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return null;
    }
  }
}
