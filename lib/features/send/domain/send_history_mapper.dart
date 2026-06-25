import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/history/transfer_record_status.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

/// Builds a sent-direction [TransferRecord] from a terminal [TransferView] and
/// the files the send started with (#006, US2). The originating disk path is
/// carried per file so re-send can later check existence (FR-020/021). `id` and
/// `createdAt` are stamped by the caller at the terminal call site (FR-004).
abstract final class SendHistoryMapper {
  static TransferRecord toRecord({
    required String id,
    required DateTime createdAt,
    required List<FileSource> sources,
    required TransferView view,
    String peerLabel = '',
  }) {
    final items = view.items;
    return TransferRecord(
      id: id,
      direction: TransferDirection.sent,
      status: historyStatusForView(view),
      pairingMethod: PairingMethod.sixDigitCode,
      peerLabel: peerLabel,
      fileCount: sources.length,
      totalBytes: sources.fold(0, (sum, s) => sum + s.size),
      createdAt: createdAt,
      files: [
        for (var i = 0; i < sources.length; i++)
          RecordedFile(
            name: sources[i].name,
            size: sources[i].size,
            mimeType: sources[i].mimeType,
            path: sources[i] is DiskFileSource
                ? (sources[i] as DiskFileSource).path
                : null,
            included:
                i < items.length && items[i].status == FileItemStatus.completed,
          ),
      ],
    );
  }
}
