import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/history/transfer_record_status.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

/// Builds a received-direction [TransferRecord] from a terminal [TransferView]
/// (#006, US2). `fileCount`/`totalBytes` reflect the **offered** manifest, so a
/// partial outcome reads "X of N"; each completed file carries its final
/// on-device path for the open action. `id`/`createdAt` are stamped by the
/// caller at the terminal call site (FR-004).
abstract final class ReceiveHistoryMapper {
  static TransferRecord toRecord({
    required String id,
    required DateTime createdAt,
    required TransferView view,
    PairingMethod pairingMethod = PairingMethod.sixDigitCode,
    String peerLabel = '',
  }) {
    return TransferRecord(
      id: id,
      direction: TransferDirection.received,
      status: historyStatusForView(view),
      pairingMethod: pairingMethod,
      peerLabel: peerLabel,
      fileCount: view.items.length,
      totalBytes: view.items.fold(0, (sum, i) => sum + i.size),
      createdAt: createdAt,
      files: [
        for (final item in view.items)
          RecordedFile(
            name: item.name,
            size: item.size,
            mimeType: item.mimeType,
            path: item.status == FileItemStatus.completed
                ? item.finalPath
                : null,
            included: item.status == FileItemStatus.completed,
          ),
      ],
    );
  }
}
