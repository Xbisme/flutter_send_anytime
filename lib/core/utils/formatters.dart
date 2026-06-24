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
}
