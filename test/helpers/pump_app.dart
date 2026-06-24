import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Pumps a child widget inside a localized, themed app for widget tests.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget child, {
    Locale locale = const Locale('vi'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return pumpWidget(
      MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }
}
