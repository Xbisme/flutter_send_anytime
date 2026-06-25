import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/services/file/file_picker_service.dart';
import 'package:safe_send/core/utils/app_logger.dart';

/// [FilePickerService] backed by `file_picker` (system document picker). Any
/// file type, multi-select, streamed from disk (`withData: false`) so large
/// files are never buffered in memory. Picked paths are never logged
/// (Constitution I).
@Injectable(as: FilePickerService)
class FilePickerServiceImpl implements FilePickerService {
  const FilePickerServiceImpl();

  @override
  Future<Result<List<FileSource>>> pickFiles() async {
    try {
      // withData defaults to false on IO → files stream from disk (no buffering).
      final result = await FilePicker.pickFiles(allowMultiple: true);
      if (result == null) {
        // User cancelled — not an error; selection is unchanged.
        return const Result.success(<FileSource>[]);
      }
      final sources = <FileSource>[
        for (final file in result.files)
          if (file.path != null) DiskFileSource(file.path!),
      ];
      return Result.success(sources);
    } on Object catch (error) {
      // Log the error TYPE only — never the message (it may embed a path).
      AppLogger.error('file pick failed (${error.runtimeType})');
      return const Result.failure(AppFailure.unexpected());
    }
  }
}
