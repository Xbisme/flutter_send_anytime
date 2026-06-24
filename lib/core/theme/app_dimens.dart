import 'package:flutter/widgets.dart';

/// Spacing scale (4px base).
abstract final class AppSpacing {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
  static const x16 = 64.0;
  static const x20 = 80.0;
}

/// Corner radii (rendered-screen values — soft, not the source CSS's `0`).
abstract final class AppRadii {
  static const chip = 12.0;
  static const card = 16.0;
  static const cardLg = 18.0;
  static const hero = 22.0;
  static const pill = 999.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const cardLgRadius = BorderRadius.all(Radius.circular(cardLg));
  static const heroRadius = BorderRadius.all(Radius.circular(hero));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
}

/// Elevation tokens.
abstract final class AppShadow {
  static const softLight = [
    BoxShadow(
      color: Color(0x12070B09),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const softDark = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const accentGlow = [
    BoxShadow(
      color: Color(0x5200C853),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];
}

/// Motion tokens. Decorative animations must freeze under Reduce Motion.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 360);
  static const easeOut = Cubic(0.16, 1, 0.3, 1);

  /// Minimum interactive target size.
  static const tapTarget = 44.0;
}
