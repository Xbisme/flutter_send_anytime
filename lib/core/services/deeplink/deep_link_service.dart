/// Core deep-link delivery seam (#008). Abstracts the OS deep-link plumbing so
/// the app's link handling stays testable and free of plugin coupling. Imports
/// no features and MUST NOT log URL contents (Constitution I).
abstract interface class DeepLinkService {
  /// The link that cold-started the app, or null. Call once after the app is
  /// ready (router + DI initialized) so the launching invite is not lost.
  Future<Uri?> getInitialLink();

  /// Links delivered while the app is already running (warm start).
  Stream<Uri> get links;
}
