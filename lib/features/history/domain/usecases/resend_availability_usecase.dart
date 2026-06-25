import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';

/// Decides whether a sent record can be re-sent and reconstructs its file
/// sources (#006, US5). Re-send is **all-or-nothing** (FR-020/021): available
/// only when every original source file still exists on disk. Only reads the
/// filesystem — never writes.
@injectable
class ResendAvailabilityUseCase {
  const ResendAvailabilityUseCase();

  /// True when every file in [record] has a path that still exists on disk.
  bool isAvailable(TransferRecord record) {
    if (record.files.isEmpty) return false;
    return record.files.every(
      (f) => f.path != null && File(f.path!).existsSync(),
    );
  }

  /// Reconstruct the [FileSource]s for re-sending [record]. Call only when
  /// [isAvailable] is true.
  List<FileSource> toSources(TransferRecord record) => [
    for (final f in record.files)
      if (f.path != null) DiskFileSource(f.path!, mimeType: f.mimeType),
  ];
}
