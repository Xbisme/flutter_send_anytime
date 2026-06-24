import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/router/app_router.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';
import 'package:toastification/toastification.dart';

/// Root application widget. Fixed light/dark palette via [AppTheme] +
/// [ThemeMode.system]; Vietnamese-primary localization with a Vietnamese
/// fallback for unsupported device languages.
class SafeSendApp extends StatelessWidget {
  const SafeSendApp({this.router, super.key});

  /// Optional router override (tests inject a fresh [createAppRouter]).
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).navHome,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        // themeMode defaults to ThemeMode.system — the app follows the OS
        // theme; there is no in-app scheme picker (#001).
        routerConfig: router ?? appRouter,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: (locale, supported) {
          if (locale != null) {
            for (final l in supported) {
              if (l.languageCode == locale.languageCode) return l;
            }
          }
          // Fallback to Vietnamese (primary product language).
          return const Locale('vi');
        },
      ),
    );
  }
}
