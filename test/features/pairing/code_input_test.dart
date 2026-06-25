import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/presentation/inputs/code_box.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_input.dart';

import '../../helpers/pump_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required ValueChanged<String> onChanged,
    ValueChanged<String>? onCompleted,
  }) => tester.pumpApp(
    Scaffold(
      body: CodeInput(onChanged: onChanged, onCompleted: onCompleted),
    ),
  );

  testWidgets('renders six code cells', (tester) async {
    await pump(tester, onChanged: (_) {});
    expect(find.byType(CodeBox), findsNWidgets(6));
  });

  testWidgets('strips non-digits and reports the digit-only value', (
    tester,
  ) async {
    String? changed;
    await pump(tester, onChanged: (v) => changed = v);
    await tester.enterText(find.byType(TextField), 'a1b2c3');
    expect(changed, '123');
  });

  testWidgets('fires onCompleted only once all six digits are entered, '
      'preserving leading zeros', (tester) async {
    String? changed;
    String? completed;
    await pump(
      tester,
      onChanged: (v) => changed = v,
      onCompleted: (v) => completed = v,
    );

    await tester.enterText(find.byType(TextField), '0123');
    expect(changed, '0123');
    expect(completed, isNull);

    await tester.enterText(find.byType(TextField), '012345');
    expect(changed, '012345');
    expect(completed, '012345');
  });

  testWidgets('clamps input to six digits', (tester) async {
    String? changed;
    await pump(tester, onChanged: (v) => changed = v);
    await tester.enterText(find.byType(TextField), '12345678');
    expect(changed, '123456');
  });
}
