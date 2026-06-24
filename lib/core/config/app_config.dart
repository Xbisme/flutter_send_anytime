import 'package:safe_send/core/config/app_flavor.dart';

/// Immutable per-flavor app configuration, provided at startup by the flavor
/// entry point and registered in the DI container.
class AppConfig {
  const AppConfig({
    required this.flavor,
    this.appName = 'Safe Send',
    this.deepLinkScheme = 'safesend',
  });

  /// Active build flavor.
  final AppFlavor flavor;

  /// User-facing app name.
  final String appName;

  /// Reserved deep-link scheme (no handlers wired in #001).
  final String deepLinkScheme;
}
