import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/services/media/media_controller.dart';
import 'package:safe_send/core/services/media/video_thumbnail_service.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_player_cubit.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_viewer_cubit.dart';

/// Guards that #013's viewer services/cubits are actually wired into the real
/// DI graph — the widget tests use fakes, so a missing `@LazySingleton` /
/// `@injectable` would otherwise only surface at runtime.
void main() {
  setUp(() => configureDependencies(const AppConfig(flavor: AppFlavor.dev)));
  tearDown(() async => getIt.reset());

  test('viewer services + cubits resolve from the real graph', () {
    expect(getIt<VideoThumbnailService>(), isNotNull);
    expect(getIt<MediaControllerFactory>(), isNotNull);
    expect(getIt<MediaPlayerCubit>(), isNotNull);
    expect(getIt<TextViewerCubit>(), isNotNull);
  });
}
