import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Read-only build facts for the About section (#010, FR-016).
// ignore: one_member_abstracts
abstract interface class AppInfoService {
  /// The installed app version (e.g. "1.0.0").
  Future<String> version();
}

/// `package_info_plus`-backed implementation.
@LazySingleton(as: AppInfoService)
class PackageInfoAppInfoService implements AppInfoService {
  @override
  Future<String> version() async => (await PackageInfo.fromPlatform()).version;
}
