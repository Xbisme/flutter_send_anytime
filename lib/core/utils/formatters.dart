import 'dart:math' as math;

import 'package:intl/intl.dart';

/// Locale-aware formatting helpers for sizes, counts and dates (FR-025).
abstract final class Formatters {
  /// Human-readable byte size, e.g. `240 MB`, `1.2 GB`.
  static String bytes(int value, {String? locale}) {
    if (value <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    final digitGroups = (math.log(value) / math.log(1024)).floor();
    final unitIndex = math.min(digitGroups, units.length - 1);
    final size = value / math.pow(1024, unitIndex);
    final pattern = unitIndex == 0 ? '#,##0' : '#,##0.#';
    return '${NumberFormat(pattern, locale).format(size)} ${units[unitIndex]}';
  }

  /// Grouped integer, e.g. `1,247`.
  static String count(int value, {String? locale}) =>
      NumberFormat('#,##0', locale).format(value);

  /// Short time of day, e.g. `14:20`.
  static String timeOfDay(DateTime dateTime, {String? locale}) =>
      DateFormat.Hm(locale).format(dateTime);

  /// Transfer rate, e.g. `2.4 MB/s` (per-second byte size).
  static String speed(double bytesPerSec, {String? locale}) {
    final rounded = bytesPerSec <= 0 ? 0 : bytesPerSec.round();
    return '${bytes(rounded, locale: locale)}/s';
  }

  /// Clock-style duration `m:ss` (or `h:mm:ss` past an hour), e.g. `1:05`.
  static String clock(Duration duration) {
    final total = duration.isNegative ? Duration.zero : duration;
    final hours = total.inHours;
    final minutes = total.inMinutes.remainder(60);
    final seconds = total.inSeconds.remainder(60);
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final mm = minutes.toString().padLeft(2, '0');
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
  }
}
