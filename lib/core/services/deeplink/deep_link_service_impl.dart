import 'package:app_links/app_links.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/services/deeplink/deep_link_service.dart';

/// [DeepLinkService] backed by `app_links` (#008). The cold-start launch URL
/// comes from [AppLinks.getInitialLink]; subsequent warm links from
/// [AppLinks.uriLinkStream]. Never logs the URL — the payload carries the
/// rendezvous code (Constitution I).
@LazySingleton(as: DeepLinkService)
class DeepLinkServiceImpl implements DeepLinkService {
  DeepLinkServiceImpl() : _appLinks = AppLinks();

  final AppLinks _appLinks;

  @override
  Future<Uri?> getInitialLink() async {
    try {
      return await _appLinks.getInitialLink();
    } on Object {
      // No launching link / platform unavailable (e.g. tests) — nothing to do.
      return null;
    }
  }

  @override
  Stream<Uri> get links => _appLinks.uriLinkStream;
}
