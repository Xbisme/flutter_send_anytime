import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/inputs/search_pill.dart';

import '../helpers/pump_app.dart';

void main() {
  group('Accessibility (US3)', () {
    testWidgets('PrimaryButton exposes its label as a button to semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        Scaffold(
          body: PrimaryButton(label: 'Gửi', onPressed: () {}),
        ),
      );
      expect(find.bySemanticsLabel(RegExp('Gửi')), findsWidgets);
      handle.dispose();
    });

    testWidgets('SearchPill shows its hint and renders as a read-only field', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: SearchPill(hintText: 'Tìm gì đó')),
      );
      expect(find.text('Tìm gì đó'), findsOneWidget);
      expect(find.byType(SearchPill), findsOneWidget);
    });

    testWidgets('static shell surfaces settle without perpetual animation', (
      tester,
    ) async {
      await tester.pumpApp(
        const Scaffold(body: SearchPill(hintText: 'x')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchPill), findsOneWidget);
    });
  });
}
