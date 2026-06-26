import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/receive/domain/receive_history_mapper.dart';

void main() {
  const view = TransferView(
    phase: TransferPhase.done,
    role: TransferRole.receiver,
    items: [
      FileTransferItem(
        index: 0,
        name: 'a.pdf',
        size: 10,
        status: FileItemStatus.completed,
        finalPath: '/docs/a.pdf',
      ),
    ],
  );

  test('defaults pairingMethod to sixDigitCode', () {
    final record = ReceiveHistoryMapper.toRecord(
      id: 'x',
      createdAt: DateTime(2026),
      view: view,
    );
    expect(record.pairingMethod, PairingMethod.sixDigitCode);
  });

  test('records pairingMethod = qr when paired via QR (FR-018)', () {
    final record = ReceiveHistoryMapper.toRecord(
      id: 'x',
      createdAt: DateTime(2026),
      view: view,
      pairingMethod: PairingMethod.qr,
    );
    expect(record.pairingMethod, PairingMethod.qr);
    expect(record.direction, TransferDirection.received);
  });

  test('records pairingMethod = shareLink when paired via a link (FR-017)', () {
    final record = ReceiveHistoryMapper.toRecord(
      id: 'x',
      createdAt: DateTime(2026),
      view: view,
      pairingMethod: PairingMethod.shareLink,
    );
    expect(record.pairingMethod, PairingMethod.shareLink);
    expect(record.direction, TransferDirection.received);
  });
}
