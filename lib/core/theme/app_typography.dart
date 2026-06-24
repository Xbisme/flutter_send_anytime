import 'package:flutter/material.dart';

/// Typography tokens. Sora for display/body; JetBrains Mono for codes, sizes,
/// rates, counts and timestamps (always with tabular figures).
abstract final class AppTypography {
  static const fontDisplay = 'Sora';
  static const fontMono = 'JetBrainsMono';

  static const _tabular = [FontFeature.tabularFigures()];

  /// Build a Material [TextTheme] in Sora for the given text color.
  static TextTheme textTheme(Color color) {
    TextStyle s(double size, FontWeight weight, {double tracking = 0}) =>
        TextStyle(
          fontFamily: fontDisplay,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: tracking,
          color: color,
          height: 1.25,
        );

    return TextTheme(
      displayLarge: s(60, FontWeight.w800, tracking: -1.2),
      displayMedium: s(48, FontWeight.w800, tracking: -0.96),
      displaySmall: s(36, FontWeight.w800, tracking: -0.72),
      headlineLarge: s(28, FontWeight.w800, tracking: -0.56),
      headlineMedium: s(23, FontWeight.w800, tracking: -0.46),
      headlineSmall: s(20, FontWeight.w700),
      titleLarge: s(19, FontWeight.w700),
      titleMedium: s(16, FontWeight.w700),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400).copyWith(height: 1.5),
      bodyMedium: s(14, FontWeight.w400).copyWith(height: 1.5),
      bodySmall: s(12, FontWeight.w400).copyWith(height: 1.5),
      labelLarge: s(14, FontWeight.w600),
      labelMedium: s(12, FontWeight.w600),
      labelSmall: s(11, FontWeight.w600),
    );
  }

  /// Monospaced style for technical/numeric values.
  static TextStyle mono({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
    double tracking = 0,
  }) => TextStyle(
    fontFamily: fontMono,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color,
    fontFeatures: _tabular,
  );
}
