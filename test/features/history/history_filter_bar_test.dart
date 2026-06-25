import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/history/presentation/widgets/history_filter_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets(
    'typing reports the query; segments report direction; date fires',
    (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? query;
      TransferDirection? direction = TransferDirection.sent; // sentinel
      var pickedDate = false;

      await tester.pumpApp(
        Scaffold(
          body: HistoryFilterBar(
            controller: controller,
            direction: null,
            hasDateFilter: false,
            onQueryChanged: (q) => query = q,
            onDirectionChanged: (d) => direction = d,
            onPickDate: () => pickedDate = true,
            onClearDate: () {},
          ),
        ),
        locale: const Locale('en'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'report');
      expect(query, 'report');

      await tester.tap(find.text('Received'));
      expect(direction, TransferDirection.received);

      await tester.tap(find.text('All'));
      expect(direction, isNull);

      await tester.tap(find.byIcon(LucideIcons.calendar));
      expect(pickedDate, isTrue);
    },
  );
}
