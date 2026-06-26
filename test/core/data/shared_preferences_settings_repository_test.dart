import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/data/shared_preferences_settings_repository.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/preference_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferencesSettingsRepository build({
    AppFlavor flavor = AppFlavor.dev,
  }) => SharedPreferencesSettingsRepository(AppConfig(flavor: flavor));

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SharedPreferencesSettingsRepository', () {
    test('first init generates and persists a default device name', () async {
      final repo = build();
      await repo.init();

      expect(repo.current.deviceName, startsWith('Safe Send'));
      expect(repo.current.deviceName.trim(), isNotEmpty);

      // A second repo over the same store keeps the same name.
      final repo2 = build();
      await repo2.init();
      expect(repo2.current.deviceName, repo.current.deviceName);
    });

    test('defaults are OFF / system / no override (FR-021)', () async {
      final repo = build();
      await repo.init();
      final s = repo.current;
      expect(s.autoReceive, isFalse);
      expect(s.saveToLibrary, isFalse);
      expect(s.notifications, isFalse);
      expect(s.theme, ThemePreference.system);
      expect(s.language, LanguagePreference.system);
      expect(s.signalingOverride, isNull);
    });

    test('setters persist and emit on watch()', () async {
      final repo = build();
      await repo.init();
      final emitted = <bool>[];
      final sub = repo.watch().listen((s) => emitted.add(s.autoReceive));

      await repo.setAutoReceive(value: true);
      await repo.setTheme(ThemePreference.dark);

      expect(repo.current.autoReceive, isTrue);
      expect(repo.current.theme, ThemePreference.dark);
      expect(emitted, contains(true));

      // Persisted across a reload.
      final repo2 = build();
      await repo2.init();
      expect(repo2.current.autoReceive, isTrue);
      expect(repo2.current.theme, ThemePreference.dark);
      await sub.cancel();
    });

    group('device-name validation (FR-002)', () {
      test('rejects empty / whitespace and keeps prior name', () async {
        final repo = build();
        await repo.init();
        final prior = repo.current.deviceName;

        expect(await repo.setDeviceName('   '), isA<Failure<void>>());
        expect(repo.current.deviceName, prior);
      });

      test('rejects > 30 chars', () async {
        final repo = build();
        await repo.init();
        final result = await repo.setDeviceName('x' * 31);
        expect(result, isA<Failure<void>>());
      });

      test('accepts a valid trimmed name', () async {
        final repo = build();
        await repo.init();
        final result = await repo.setDeviceName("  Minh's iPhone  ");
        expect(result, isA<Success<void>>());
        expect(repo.current.deviceName, "Minh's iPhone");
      });
    });

    group('signaling-endpoint validation (FR-014)', () {
      test('accepts wss in any flavor', () async {
        final prod = build(flavor: AppFlavor.prod);
        await prod.init();
        expect(
          await prod.setSignalingOverride(
            Uri.parse('wss://relay.example:8443'),
          ),
          isA<Success<void>>(),
        );
        expect(prod.current.signalingOverride, isNotNull);
      });

      test('accepts ws only in dev', () async {
        final dev = build();
        await dev.init();
        expect(
          await dev.setSignalingOverride(Uri.parse('ws://localhost:8080')),
          isA<Success<void>>(),
        );

        final prod = build(flavor: AppFlavor.prod);
        await prod.init();
        expect(
          await prod.setSignalingOverride(Uri.parse('ws://localhost:8080')),
          isA<Failure<void>>(),
        );
      });

      test('rejects other schemes and unparseable hosts', () async {
        final repo = build();
        await repo.init();
        expect(
          await repo.setSignalingOverride(Uri.parse('http://x.example')),
          isA<Failure<void>>(),
        );
        expect(
          await repo.setSignalingOverride(Uri.parse('wss://')),
          isA<Failure<void>>(),
        );
      });

      test('null clears the override', () async {
        final repo = build();
        await repo.init();
        await repo.setSignalingOverride(Uri.parse('wss://relay.example'));
        expect(await repo.setSignalingOverride(null), isA<Success<void>>());
        expect(repo.current.signalingOverride, isNull);
      });
    });
  });
}
