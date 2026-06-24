import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';

part 'file_transfer_item.freezed.dart';

/// Lifecycle of a single file within a session.
enum FileItemStatus {
  /// Not started yet.
  pending,

  /// Bytes are streaming.
  transferring,

  /// All bytes received; integrity being checked (receiver).
  verifying,

  /// Verified and placed (receiver) / fully sent (sender).
  completed,

  /// This file failed (fails the whole session — fail-fast).
  failed,
}

/// One file inside a transfer session. Progress fields evolve via `copyWith`.
@freezed
abstract class FileTransferItem with _$FileTransferItem {
  const factory FileTransferItem({
    required int index,
    required String name,
    required int size,
    String? mimeType,
    String? sha256,
    @Default(0) int bytesTransferred,
    @Default(FileItemStatus.pending) FileItemStatus status,
    AppFailure? failure,
    String? quarantinePath,
    String? finalPath,
  }) = _FileTransferItem;

  const FileTransferItem._();

  /// Whether this file has reached a terminal status.
  bool get isTerminal =>
      status == FileItemStatus.completed || status == FileItemStatus.failed;
}
