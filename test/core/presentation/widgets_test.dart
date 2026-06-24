import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_empty_view.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/presentation/scaffolding/coming_soon_view.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Shared widgets', () {
    testWidgets('PrimaryButton shows label and fires onPressed', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpApp(
        Scaffold(
          body: PrimaryButton(
            label: 'Tiếp tục',
            onPressed: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Tiếp tục'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục'));
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton dims to 50% opacity when disabled', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(
          body: PrimaryButton(label: 'Off', onPressed: null),
        ),
      );
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Off'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('FileChip renders the uppercased extension', (tester) async {
      await tester.pumpApp(const Scaffold(body: FileChip(ext: 'pdf')));
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('FileRow shows name and meta', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: FileRow(name: 'a.pdf', ext: 'PDF', meta: '4 MB'),
        ),
      );
      expect(find.text('a.pdf'), findsOneWidget);
      expect(find.text('4 MB'), findsOneWidget);
    });

    testWidgets('AppEmptyView shows icon, title and body', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: AppEmptyView(
            icon: LucideIcons.history,
            title: 'Empty',
            body: 'Nothing here',
          ),
        ),
      );
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('ComingSoonView shows title and body', (tester) async {
      await tester.pumpApp(
        const Scaffold(
          body: ComingSoonView(
            icon: LucideIcons.send,
            title: 'Sắp ra mắt',
            body: 'Soon',
          ),
        ),
      );
      expect(find.text('Sắp ra mắt'), findsOneWidget);
      expect(find.text('Soon'), findsOneWidget);
    });
  });
}
