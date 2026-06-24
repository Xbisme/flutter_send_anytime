/// Build flavor. Drives application id, display name and (later) the signaling
/// endpoint.
enum AppFlavor {
  /// Development flavor (`app.safesend.dev`).
  dev,

  /// Production flavor (`app.safesend`).
  prod
  ;

  /// Whether this is the development flavor.
  bool get isDev => this == AppFlavor.dev;
}
