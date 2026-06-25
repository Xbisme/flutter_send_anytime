import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/services/file/file_picker_service.dart';

/// Opens the system picker and returns the chosen files (#004).
@injectable
class PickFilesUseCase {
  const PickFilesUseCase(this._picker);

  final FilePickerService _picker;

  /// Pick any-type, multi-select files; empty list if the user cancels.
  Future<Result<List<FileSource>>> call() => _picker.pickFiles();
}
