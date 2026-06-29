import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:safe_send/core/utils/received_file_path.dart';
import 'package:share_plus/share_plus.dart';

/// Default [ReceivedFilesService]: app documents dir + system share/open. No
/// runtime permission needed (Constitution VII / research R3). Never logs paths.
@LazySingleton(as: ReceivedFilesService)
class ReceivedFilesServiceImpl implements ReceivedFilesService {
  static const _subdir = 'SafeSend';

  @override
  Future<Result<Directory>> destinationDirectory() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}${Platform.pathSeparator}$_subdir');
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return Result.success(dir);
    } on Object catch (error) {
      AppLogger.error('destination dir failed (${error.runtimeType})');
      return const Result.failure(AppFailure.fileWriteFailed());
    }
  }

  @override
  Future<Result<void>> share(List<String> paths) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: paths.map(ReceivedFilePath.resolve).map(XFile.new).toList(),
        ),
      );
      return const Result.success(null);
    } on Object catch (error) {
      AppLogger.error('share failed (${error.runtimeType})');
      return const Result.failure(AppFailure.unexpected(message: 'share'));
    }
  }

  @override
  Future<Result<void>> open(String path) async {
    try {
      final result = await OpenFilex.open(ReceivedFilePath.resolve(path));
      if (result.type == ResultType.done) return const Result.success(null);
      AppLogger.error('open failed (${result.type})');
      return const Result.failure(AppFailure.unexpected(message: 'open'));
    } on Object catch (error) {
      AppLogger.error('open threw (${error.runtimeType})');
      return const Result.failure(AppFailure.unexpected(message: 'open'));
    }
  }
}
