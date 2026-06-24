import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme exposes the light AppColors extension', () {
      final colors = AppTheme.light.extension<AppColors>();
      expect(colors, isNotNull);
      expect(colors!.bgBase, AppColors.light.bgBase);
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('dark theme exposes the dark AppColors extension', () {
      final colors = AppTheme.dark.extension<AppColors>();
      expect(colors, isNotNull);
      expect(colors!.bgBase, AppColors.dark.bgBase);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('light and dark resolve different primary text colors', () {
      expect(
        AppColors.light.textPrimary,
        isNot(AppColors.dark.textPrimary),
      );
    });

    testWidgets('AppColors.of resolves the active extension', (tester) async {
      late AppColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              resolved = AppColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved.bgBase, AppColors.dark.bgBase);
    });
  });
}
