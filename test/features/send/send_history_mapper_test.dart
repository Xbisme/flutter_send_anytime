import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/send/domain/send_history_mapper.dart';

void main() {
  final sources = [DiskFileSource('/tmp/a.pdf')];
  const view = TransferView(
    phase: TransferPhase.done,
    role: TransferRole.sender,
    items: [
      FileTransferItem(
        index: 0,
        name: 'a.pdf',
        size: 10,
        status: FileItemStatus.completed,
      ),
    ],
  );

  test('defaults pairingMethod to sixDigitCode', () {
    final record = SendHistoryMapper.toRecord(
      id: 'x',
      createdAt: DateTime(2026),
      sources: sources,
      view: view,
    );
    expect(record.pairingMethod, PairingMethod.sixDigitCode);
  });

  test('records pairingMethod = qr when paired via QR (FR-018)', () {
    final record = SendHistoryMapper.toRecord(
      id: 'x',
      createdAt: DateTime(2026),
      sources: sources,
      view: view,
      pairingMethod: PairingMethod.qr,
    );
    expect(record.pairingMethod, PairingMethod.qr);
    expect(record.direction, TransferDirection.sent);
  });

  test(
    'records pairingMethod = nearby when paired via radar (#009 FR-010)',
    () {
      final record = SendHistoryMapper.toRecord(
        id: 'x',
        createdAt: DateTime(2026),
        sources: sources,
        view: view,
        pairingMethod: PairingMethod.nearby,
      );
      expect(record.pairingMethod, PairingMethod.nearby);
      expect(record.direction, TransferDirection.sent);
    },
  );
}
