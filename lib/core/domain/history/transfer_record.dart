import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

part 'transfer_record.freezed.dart';

/// One finished transfer, persisted by History (#006). Holds transfer
/// **metadata only** — never file contents (Constitution II). The unit shown in
/// the History list, the detail page, and the Home recent area.
///
/// [peerLabel] is empty today (no device name is exchanged by #002/#003); the
/// UI shows a generic localized label keyed by [direction]. A real name fills
/// this field in #010 without a schema change (FR-008).
@freezed
abstract class TransferRecord with _$TransferRecord {
  const factory TransferRecord({
    required String id,
    required TransferDirection direction,
    required TransferRecordStatus status,
    required PairingMethod pairingMethod,
    required int fileCount,
    required int totalBytes,
    required DateTime createdAt,
    @Default('') String peerLabel,
    @Default(<RecordedFile>[]) List<RecordedFile> files,
  }) = _TransferRecord;

  const TransferRecord._();

  /// Files that actually completed and were kept (FR-013a). For a `completed`
  /// record this is all files; for a `partial` one, only those that landed.
  List<RecordedFile> get includedFiles =>
      files.where((f) => f.included).toList();

  /// Whether every offered file is represented and openable/re-sendable.
  bool get isComplete => status == TransferRecordStatus.completed;
}

/// A single file inside a [TransferRecord]. [path] is the original source path
/// (sent — for re-send existence checks) or the final on-device path (received
/// — for open); null when unknown/not applicable. [included] marks whether the
/// file completed in the transfer.
@freezed
abstract class RecordedFile with _$RecordedFile {
  const factory RecordedFile({
    required String name,
    required int size,
    String? mimeType,
    String? path,
    @Default(true) bool included,
  }) = _RecordedFile;

  const RecordedFile._();

  /// Upper-case extension (no dot) derived from [name], for the file chip.
  String get ext {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toUpperCase();
  }
}
