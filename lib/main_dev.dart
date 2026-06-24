import 'package:safe_send/bootstrap.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';

Future<void> main() => bootstrap(const AppConfig(flavor: AppFlavor.dev));
