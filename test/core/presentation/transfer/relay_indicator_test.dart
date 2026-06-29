import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_view.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(body: child),
  );

  TransferView view({required bool relayInUse}) => TransferView(
    phase: TransferPhase.transferring,
    role: TransferRole.sender,
    overallProgress: 0.5,
    relayInUse: relayInUse,
  );

  testWidgets('shows the relayed · encrypted indicator when relay is in use', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        TransferProgressView(
          view: view(relayInUse: true),
          onCancel: () async {},
        ),
      ),
    );
    expect(find.text('Relayed · encrypted'), findsOneWidget);
  });

  testWidgets('hides the indicator on a direct transfer', (tester) async {
    await tester.pumpWidget(
      wrap(
        TransferProgressView(
          view: view(relayInUse: false),
          onCancel: () async {},
        ),
      ),
    );
    expect(find.text('Relayed · encrypted'), findsNothing);
  });
}
