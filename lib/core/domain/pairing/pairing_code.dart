import 'package:freezed_annotation/freezed_annotation.dart';

part 'pairing_code.freezed.dart';

/// A short-lived 6-digit pairing code bound to a signaling room.
///
/// [value] is always exactly six digits with leading zeros preserved (FR-002).
/// [expiresAt] drives the countdown shown to the sender (FR-005).
@freezed
abstract class PairingCode with _$PairingCode {
  const factory PairingCode({
    required String value,
    required DateTime expiresAt,
  }) = _PairingCode;

  const PairingCode._();

  /// Build a code valid for [ttl] starting [from] (defaults to now).
  factory PairingCode.fromTtl({
    required String value,
    required Duration ttl,
    DateTime? from,
  }) {
    final start = from ?? DateTime.now();
    return PairingCode(value: value, expiresAt: start.add(ttl));
  }

  /// Time left before the code expires, clamped to zero (never negative).
  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// Whether the code has expired.
  bool get isExpired => remaining == Duration.zero;
}
