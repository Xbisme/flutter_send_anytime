/// User-selectable app theme mode (#010). The palette itself is fixed
/// (Constitution VI) — this only chooses light / dark / follow-system.
enum ThemePreference {
  /// Always light palette.
  light,

  /// Always dark palette.
  dark,

  /// Follow the OS theme.
  system,
}

/// User-selectable app language (#010). `system` follows the device locale,
/// falling back to Vietnamese for unsupported locales (Constitution XIV).
enum LanguagePreference {
  /// Force Vietnamese.
  vietnamese,

  /// Force English.
  english,

  /// Follow the OS locale (VI fallback).
  system,
}
