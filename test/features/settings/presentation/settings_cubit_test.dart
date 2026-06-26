import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/app_settings.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/features/settings/presentation/cubit/settings_cubit.dart';
import '../../../helpers/settings_fakes.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

const _initial = AppSettings(deviceName: 'Safe Send · TEST');

void main() {
  late _MockSettingsRepository repo;
  late StreamController<AppSettings> stream;

  setUpAll(() => registerFallbackValue(ThemePreference.system));

  setUp(() {
    repo = _MockSettingsRepository();
    stream = StreamController<AppSettings>.broadcast();
    when(() => repo.current).thenReturn(_initial);
    when(repo.watch).thenAnswer((_) => stream.stream);
    when(
      () => repo.setAutoReceive(value: any(named: 'value')),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => repo.setTheme(any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  tearDown(() => stream.close());

  test('emits loaded with the current snapshot on construction', () {
    final cubit = makeSettingsCubit(repo: repo);
    expect(cubit.state, isA<AppLoaded<AppSettings>>());
    expect((cubit.state as AppLoaded<AppSettings>).data, _initial);
  });

  blocTest<SettingsCubit, AppState<AppSettings>>(
    'emits loaded again when the repository stream pushes a new snapshot',
    build: () => makeSettingsCubit(repo: repo),
    act: (_) => stream.add(_initial.copyWith(autoReceive: true)),
    expect: () => [
      isA<AppLoaded<AppSettings>>().having(
        (s) => s.data.autoReceive,
        'autoReceive',
        isTrue,
      ),
    ],
  );

  test('setters forward to the repository', () async {
    final cubit = makeSettingsCubit(repo: repo);
    await cubit.setAutoReceive(value: true);
    await cubit.setTheme(ThemePreference.dark);
    verify(() => repo.setAutoReceive(value: true)).called(1);
    verify(() => repo.setTheme(ThemePreference.dark)).called(1);
    await cubit.close();
  });

  test('save-to-library denied → Failure, not persisted (FR-010)', () async {
    final cubit = makeSettingsCubit(
      repo: repo,
      photo: FakePhotoLibraryPermission()..granted = false,
    );
    final result = await cubit.setSaveToLibrary(value: true);
    expect(result, isA<Failure<void>>());
    verifyNever(() => repo.setSaveToLibrary(value: any(named: 'value')));
    await cubit.close();
  });
}
