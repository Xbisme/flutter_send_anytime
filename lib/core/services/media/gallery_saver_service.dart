import 'package:gal/gal.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';

/// Saves a received image/video into the OS photo library (#010, FR-008), in
/// addition to the existing app-sandbox save (#005). Backed by `gal`. Returns a
/// typed [Result]; the file path is never logged (Principle I).
// ignore: one_member_abstracts
abstract interface class GallerySaverService {
  Future<Result<void>> saveMedia(String filePath, {required bool isVideo});
}

/// `gal`-backed implementation.
@LazySingleton(as: GallerySaverService)
class GalGallerySaverService implements GallerySaverService {
  @override
  Future<Result<void>> saveMedia(
    String filePath, {
    required bool isVideo,
  }) async {
    try {
      if (isVideo) {
        await Gal.putVideo(filePath);
      } else {
        await Gal.putImage(filePath);
      }
      return const Result.success(null);
    } on GalException catch (e) {
      return Result.failure(_mapFailure(e.type));
    }
  }

  AppFailure _mapFailure(GalExceptionType type) => switch (type) {
    GalExceptionType.accessDenied => const AppFailure.permissionDenied(),
    GalExceptionType.notEnoughSpace => const AppFailure.storageFull(),
    GalExceptionType.notSupportedFormat ||
    GalExceptionType.unexpected => const AppFailure.fileWriteFailed(),
  };
}
