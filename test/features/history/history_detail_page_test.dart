import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/features/history/presentation/history_detail_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('renders all metadata and the full file list', (tester) async {
    final record = TransferRecord(
      id: 'a',
      direction: TransferDirection.received,
      status: TransferRecordStatus.completed,
      pairingMethod: PairingMethod.sixDigitCode,
      fileCount: 2,
      totalBytes: 3000,
      createdAt: DateTime(2026, 6, 25, 14, 20),
      files: const [
        RecordedFile(name: 'report.pdf', size: 1000),
        RecordedFile(name: 'photo.jpg', size: 2000),
      ],
    );

    await tester.pumpApp(
      HistoryDetailPage(record: record),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Received'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('6-digit code'), findsOneWidget);
    expect(find.byType(FileRow), findsNWidgets(2));
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('photo.jpg'), findsOneWidget);
  });

  testWidgets('a partial record dims the files that did not land', (
    tester,
  ) async {
    final record = TransferRecord(
      id: 'p',
      direction: TransferDirection.received,
      status: TransferRecordStatus.partial,
      pairingMethod: PairingMethod.sixDigitCode,
      fileCount: 2,
      totalBytes: 3000,
      createdAt: DateTime(2026, 6, 25, 14, 20),
      files: const [
        RecordedFile(name: 'got.pdf', size: 1000, path: '/d/got.pdf'),
        RecordedFile(name: 'lost.jpg', size: 2000, included: false),
      ],
    );

    await tester.pumpApp(
      HistoryDetailPage(record: record),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Partial'), findsOneWidget);
    final opacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .map((o) => o.opacity)
        .toList();
    expect(opacities, containsAll(<double>[1, 0.5]));
  });
}
