import 'dart:io';

import 'package:safe_send/core/domain/result.dart';

/// Save destination + export for received files (#005). Returns [Result] so the
/// cubit resolves it via `.fold` — no try/catch in cubits (Constitution V).
/// The destination is app-owned and needs NO runtime storage permission.
abstract class ReceivedFilesService {
  /// The app-owned directory received files are written into (created if
  /// absent). iOS: `<AppDocuments>/SafeSend` (browsable in Files); Android:
  /// `<AppDocuments>/SafeSend`.
  Future<Result<Directory>> destinationDirectory();

  /// Hand the given on-disk files to the system share sheet (Share-all).
  Future<Result<void>> share(List<String> paths);

  /// Open one received file in an appropriate system viewer.
  Future<Result<void>> open(String path);
}
