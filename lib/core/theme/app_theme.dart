import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_typography.dart';

/// Builds the fixed light + dark [ThemeData] from the design tokens. The app
/// uses [ThemeMode.system]; there is no in-app scheme picker.
abstract final class AppTheme {
  /// Light theme.
  static ThemeData get light => _build(Brightness.light, AppColors.light);

  /// Dark theme.
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green500,
      brightness: brightness,
      surface: c.bgSubtle,
      primary: c.accent,
      onPrimary: c.textOnAccent,
      error: AppColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bgSubtle,
      fontFamily: AppTypography.fontDisplay,
      textTheme: AppTypography.textTheme(c.textPrimary),
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
    );
  }
}
