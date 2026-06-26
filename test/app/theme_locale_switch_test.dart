import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/app/app.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/router/app_router.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';

import '../helpers/fake_history_repository.dart';
import '../helpers/settings_fakes.dart';

void main() {
  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    getIt
      ..unregister<TransferHistoryRepository>()
      ..registerFactory<TransferHistoryRepository>(FakeHistoryRepository.new);
  });
  tearDown(() async => getIt.reset());

  SettingsCubit cubitWith(AppSettings settings) =>
      makeSettingsCubit(repo: FakeSettingsRepository(settings));

  Future<MaterialApp> pumpWith(
    WidgetTester tester,
    AppSettings settings,
  ) async {
    await tester.pumpWidget(
      SafeSendApp(
        router: createAppRouter(),
        settingsCubit: cubitWith(settings),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
    return tester.widget<MaterialApp>(find.byType(MaterialApp));
  }

  testWidgets('dark + English preferences drive MaterialApp (US3)', (
    tester,
  ) async {
    final app = await pumpWith(
      tester,
      const AppSettings(
        deviceName: 'D',
        theme: ThemePreference.dark,
        language: LanguagePreference.english,
      ),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(app.locale, const Locale('en'));
  });

  testWidgets('system preferences leave themeMode.system + null locale', (
    tester,
  ) async {
    final app = await pumpWith(tester, const AppSettings(deviceName: 'D'));
    expect(app.themeMode, ThemeMode.system);
    expect(app.locale, isNull);
  });
}
