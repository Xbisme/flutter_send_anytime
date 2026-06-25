import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/features/receive/presentation/widgets/incoming_transfer_dialog.dart';

import '../../helpers/pump_app.dart';

const _offer = IncomingOffer(
  senderLabel: 'the sender',
  fileCount: 2,
  totalBytes: 300,
  typeSummary: ['JPG', 'PDF'],
);

void main() {
  testWidgets('renders the sender, manifest summary, and both actions', (
    tester,
  ) async {
    await tester.pumpApp(
      const Scaffold(body: IncomingTransferDialog(offer: _offer)),
      locale: const Locale('en'),
    );

    expect(find.textContaining('wants to send you files'), findsOneWidget);
    expect(find.textContaining('2 files'), findsOneWidget);
    expect(find.text('JPG · PDF'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('Accept pops true, Decline pops false', (tester) async {
    bool? result;
    await tester.pumpApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showIncomingTransferDialog(context, _offer);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
      locale: const Locale('en'),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
