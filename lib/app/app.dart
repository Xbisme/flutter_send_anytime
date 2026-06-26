import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/app/view/deep_link_listener.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/router/app_router.dart';
import 'package:safe_send/core/theme/app_theme.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';
import 'package:toastification/toastification.dart';

/// Root application widget. Fixed light/dark palette via [AppTheme]; theme mode
/// + language are driven by the app-wide [SettingsCubit] (#010). Vietnamese is
/// the fallback for unsupported device languages.
class SafeSendApp extends StatelessWidget {
  const SafeSendApp({this.router, this.settingsCubit, super.key});

  /// Optional router override (tests inject a fresh [createAppRouter]).
  final GoRouter? router;

  /// Optional settings-cubit override (tests inject a fake; defaults to the DI
  /// singleton).
  final SettingsCubit? settingsCubit;

  @override
  Widget build(BuildContext context) {
    final effectiveRouter = router ?? appRouter;
    return BlocProvider<SettingsCubit>.value(
      value: settingsCubit ?? getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, AppState<AppSettings>>(
        builder: (context, state) {
          final settings = state is AppLoaded<AppSettings> ? state.data : null;
          return ToastificationWrapper(
            child: MaterialApp.router(
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).navHome,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              // Theme mode driven by the user's preference (#010, US3); the
              // palette itself stays fixed.
              themeMode: _themeMode(settings?.theme),
              // Explicit locale when chosen; null follows the OS (the
              // localeResolutionCallback below applies the VI fallback).
              locale: _locale(settings?.language),
              routerConfig: effectiveRouter,
              // Route incoming safesend:// invite links (#008). The builder context
              // sits above the router's InheritedGoRouter, so the listener navigates
              // via the router instance directly (not GoRouter.of(context)).
              builder: (context, child) => DeepLinkListener(
                router: effectiveRouter,
                child: child ?? const SizedBox.shrink(),
              ),
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
        },
      ),
    );
  }

  ThemeMode _themeMode(ThemePreference? theme) => switch (theme) {
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
    ThemePreference.system || null => ThemeMode.system,
  };

  Locale? _locale(LanguagePreference? language) => switch (language) {
    LanguagePreference.vietnamese => const Locale('vi'),
    LanguagePreference.english => const Locale('en'),
    LanguagePreference.system || null => null,
  };
}
