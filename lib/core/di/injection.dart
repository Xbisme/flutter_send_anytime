import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/di/injection.config.dart';

/// Global service locator.
final GetIt getIt = GetIt.instance;

/// Initialize the DI graph. [config] is provided by the flavor entry point and
/// registered before the generated registrations run.
@InjectableInit()
Future<void> configureDependencies(AppConfig config) async {
  getIt
    ..registerSingleton<AppConfig>(config)
    ..init();
}
