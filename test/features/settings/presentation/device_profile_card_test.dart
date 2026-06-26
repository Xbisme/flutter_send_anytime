import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/settings/device_profile.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:safe_send/features/settings/presentation/widgets/device_profile_card.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/settings_fakes.dart';

void main() {
  late FakeSettingsRepository repo;

  setUp(() => repo = FakeSettingsRepository());

  Future<void> pumpCard(WidgetTester tester) => tester.pumpApp(
    BlocProvider<SettingsCubit>(
      create: (_) => makeSettingsCubit(repo: repo),
      child: const Scaffold(
        body: DeviceProfileCard(profile: DeviceProfile('Old Name')),
      ),
    ),
  );

  // Regression: the rename dialog must NOT crash on iOS — an adaptive dialog
  // there is Cupertino (no Material ancestor) and would break the TextField.
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets('rename dialog renders a TextField on $platform', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;

      await pumpCard(tester);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('saving a valid name persists it (iOS)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await pumpCard(tester);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My Phone');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(repo.current.deviceName, 'My Phone');

    debugDefaultTargetPlatformOverride = null;
  });
}
