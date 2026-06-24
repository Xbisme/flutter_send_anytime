import 'package:flutter/material.dart';

/// Fixed Safe Send palette. Light is the default; dark flips the semantic
/// aliases. Base ramps are constant across themes. Values are the rendered
/// design tokens (see contracts/design-tokens.md). Never hardcode hex at call
/// sites — resolve through [AppColors.of].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bgBase,
    required this.bgSubtle,
    required this.surfaceCard,
    required this.surfaceSunken,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    required this.accent,
    required this.accentHover,
    required this.accentPress,
    required this.accentSubtle,
    required this.accentBorder,
    required this.overlay,
  });

  final Color bgBase;
  final Color bgSubtle;
  final Color surfaceCard;
  final Color surfaceSunken;
  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textOnAccent;
  final Color accent;
  final Color accentHover;
  final Color accentPress;
  final Color accentSubtle;
  final Color accentBorder;
  final Color overlay;

  // ---- Constant base ramp + status (theme-independent) ----
  static const green50 = Color(0xFFE6FBEF);
  static const green200 = Color(0xFF8DECB6);
  static const green400 = Color(0xFF1ED66E);
  static const green500 = Color(0xFF00C853);
  static const teal500 = Color(0xFF00C2A8);
  static const info = Color(0xFF2D9CF0);
  static const success = Color(0xFF00C853);
  static const warning = Color(0xFFF5A623);
  static const danger = Color(0xFFFF4D4D);

  // ---- Gradients ----
  static const gradientBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E676), Color(0xFF00C2A8)],
  );
  static const gradientBrandVivid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1ED66E), Color(0xFF00B4D8)],
  );
  static const gradientInfo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5FB2F5), Color(0xFF2D9CF0)],
  );
  static const gradientTeal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16D8C0), Color(0xFF009E8A)],
  );

  /// On-accent text used over brand gradients (dark green for contrast).
  static const onAccentDark = Color(0xFF053019);

  static const light = AppColors(
    bgBase: Color(0xFFFFFFFF),
    bgSubtle: Color(0xFFF4F7F5),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE8EEEA),
    borderSubtle: Color(0xFFE8EEEA),
    borderDefault: Color(0xFFD6E0DA),
    borderStrong: Color(0xFFB6C4BC),
    textPrimary: Color(0xFF0E1512),
    textSecondary: Color(0xFF5B6B64),
    textMuted: Color(0xFF8A9A92),
    textOnAccent: Color(0xFF070B09),
    accent: Color(0xFF00C853),
    accentHover: Color(0xFF00A847),
    accentPress: Color(0xFF008539),
    accentSubtle: Color(0xFFE6FBEF),
    accentBorder: Color(0xFF8DECB6),
    overlay: Color(0x73070B09),
  );

  static const dark = AppColors(
    bgBase: Color(0xFF070B09),
    bgSubtle: Color(0xFF0E1512),
    surfaceCard: Color(0xFF18211D),
    surfaceSunken: Color(0xFF0E1512),
    borderSubtle: Color(0xFF18211D),
    borderDefault: Color(0xFF283330),
    borderStrong: Color(0xFF3E4B45),
    textPrimary: Color(0xFFF4F7F5),
    textSecondary: Color(0xFF8A9A92),
    textMuted: Color(0xFF5B6B64),
    textOnAccent: Color(0xFF070B09),
    accent: Color(0xFF1ED66E),
    accentHover: Color(0xFF4FE08F),
    accentPress: Color(0xFF00C853),
    accentSubtle: Color(0x2400C853),
    accentBorder: Color(0x5900C853),
    overlay: Color(0x99000000),
  );

  /// Resolve the active [AppColors] from the [BuildContext].
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? bgBase,
    Color? bgSubtle,
    Color? surfaceCard,
    Color? surfaceSunken,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textOnAccent,
    Color? accent,
    Color? accentHover,
    Color? accentPress,
    Color? accentSubtle,
    Color? accentBorder,
    Color? overlay,
  }) {
    return AppColors(
      bgBase: bgBase ?? this.bgBase,
      bgSubtle: bgSubtle ?? this.bgSubtle,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentPress: accentPress ?? this.accentPress,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      accentBorder: accentBorder ?? this.accentBorder,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgBase: Color.lerp(bgBase, other.bgBase, t)!,
      bgSubtle: Color.lerp(bgSubtle, other.bgSubtle, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentPress: Color.lerp(accentPress, other.accentPress, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      accentBorder: Color.lerp(accentBorder, other.accentBorder, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
    );
  }
}
