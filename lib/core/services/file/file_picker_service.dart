import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';

/// Picks files for sending (#004). Abstracts the platform document picker so
/// the Send feature depends on a seam, not on a specific plugin.
// ignore: one_member_abstracts
abstract interface class FilePickerService {
  /// Open the system picker for any-type, multi-select. Returns the chosen
  /// files as streamable [FileSource]s, an empty list if the user cancels, or
  /// a typed failure if the picker errors. Never exposes file paths in logs.
  Future<Result<List<FileSource>>> pickFiles();
}
