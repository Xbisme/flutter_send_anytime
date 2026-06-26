/// Outcome of ensuring the platform permission needed to advertise/browse on the
/// local network (#009), abstracted from `permission_handler` so cubits depend on
/// a small core enum and stay testable. Mirrors the #007 camera-permission seam.
enum NearbyPermissionStatus {
  /// Access is available — advertising/browsing may proceed.
  granted,

  /// Denied, but the system prompt can still be shown (re-requestable).
  denied,

  /// Denied and the OS will no longer prompt — only Settings can re-enable it.
  permanentlyDenied,
}

/// Thin seam over the nearby/local-network runtime permission (#009).
///
/// Android 13+ : the `NEARBY_WIFI_DEVICES` runtime permission gates mDNS.
/// Android <13 : no runtime gate → `granted`.
/// iOS         : no pre-request/query API exists — the OS Local Network prompt
///               fires automatically on first mDNS use, so `ensure` returns
///               `granted` and the UI relies on the rationale + empty-state.
abstract interface class NearbyPermissionService {
  /// Ensure the permission, prompting if still askable. Returns the outcome.
  Future<NearbyPermissionStatus> ensure();

  /// Open the OS app-settings page so a blocked permission can be re-enabled.
  Future<void> openSettings();
}
