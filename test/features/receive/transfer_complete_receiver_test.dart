import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_complete_view.dart';

import '../../helpers/pump_app.dart';

const _items = [
  FileTransferItem(
    index: 0,
    name: 'a.jpg',
    size: 100,
    status: FileItemStatus.completed,
    finalPath: '/tmp/a.jpg',
  ),
  FileTransferItem(
    index: 1,
    name: 'b.pdf',
    size: 200,
    status: FileItemStatus.completed,
    finalPath: '/tmp/b.pdf',
  ),
];

TransferView _view(TransferPhase phase, List<FileTransferItem> items) =>
    TransferView(
      phase: phase,
      role: TransferRole.receiver,
      bytesTotal: 300,
      fileCount: 2,
      items: items,
    );

void main() {
  testWidgets('lists files with per-file Open and a Share-all action', (
    tester,
  ) async {
    String? opened;
    List<String>? shared;
    await tester.pumpApp(
      Scaffold(
        body: TransferCompleteView(
          view: _view(TransferPhase.done, _items),
          onDone: () {},
          onOpen: (p) => opened = p,
          onShare: (p) => shared = p,
        ),
      ),
      locale: const Locale('en'),
    );

    expect(find.text('Received!'), findsOneWidget);
    expect(find.text('a.jpg'), findsOneWidget);
    expect(find.text('b.pdf'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.externalLink).first);
    await tester.pump();
    expect(opened, '/tmp/a.jpg');

    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(shared, ['/tmp/a.jpg', '/tmp/b.pdf']);
  });

  testWidgets(
    'a partial outcome shows the partial summary over the kept files',
    (
      tester,
    ) async {
      // File 0 completed, file 1 failed mid-flight → terminal failed + 1 done.
      const items = [
        FileTransferItem(
          index: 0,
          name: 'a.jpg',
          size: 100,
          status: FileItemStatus.completed,
          finalPath: '/tmp/a.jpg',
        ),
        FileTransferItem(index: 1, name: 'b.pdf', size: 200),
      ];
      final view = _view(TransferPhase.failed, items);
      expect(view.isPartial, isTrue);

      await tester.pumpApp(
        Scaffold(
          body: TransferCompleteView(view: view, onDone: () {}),
        ),
        locale: const Locale('en'),
      );

      expect(find.text('Partly received'), findsOneWidget);
      expect(find.text('a.jpg'), findsOneWidget);
      expect(find.text('b.pdf'), findsNothing);
    },
  );
}
