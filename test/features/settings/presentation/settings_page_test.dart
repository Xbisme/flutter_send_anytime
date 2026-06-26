import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/settings_page.dart';
import 'package:safe_send/features/settings/presentation/widgets/device_profile_card.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/settings_fakes.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

const _settings = AppSettings(deviceName: "Minh's iPhone", autoReceive: true);

void main() {
  late _MockSettingsRepository repo;

  setUp(() {
    repo = _MockSettingsRepository();
    when(() => repo.current).thenReturn(_settings);
    when(repo.watch).thenAnswer((_) => const Stream<AppSettings>.empty());
    when(
      () => repo.setSaveToLibrary(value: any(named: 'value')),
    ).thenAnswer((_) async => const Result.success(null));
  });

  Future<void> pumpSettings(WidgetTester tester) => tester.pumpApp(
    BlocProvider<SettingsCubit>(
      create: (_) => makeSettingsCubit(repo: repo),
      child: const SettingsPage(),
    ),
  );

  testWidgets('renders profile card + toggles without rebuild loop', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    expect(find.byType(DeviceProfileCard), findsOneWidget);
    expect(find.text("Minh's iPhone"), findsOneWidget);
    // Auto-receive reflects the snapshot (true).
    expect(find.byType(Switch), findsWidgets);
  });

  testWidgets('toggling save-to-library forwards to the cubit', (tester) async {
    await pumpSettings(tester);
    await tester.pumpAndSettle();

    // The second toggle row is save-to-library.
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    verify(() => repo.setSaveToLibrary(value: true)).called(1);
  });
}
