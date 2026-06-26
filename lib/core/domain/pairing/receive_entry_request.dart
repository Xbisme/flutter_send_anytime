/// Navigation payload for the receive entry route (`AppRoutes.receive`). Core-
/// typed so features exchange it via `go_router` `extra` without importing each
/// other (Constitution XI). Carries the two optional entry modifiers that have
/// accreted onto the Receive flow: open the QR scanner immediately (#007), and
/// auto-join a share-link-delivered code (#008).
class ReceiveEntryRequest {
  const ReceiveEntryRequest({this.openScanner = false, this.autoJoinCode});

  /// Open the QR scanner straight away (Home "Quét QR", #007, FR-019).
  final bool openScanner;

  /// A 6-digit code delivered by a share-link invite to auto-join on entry
  /// (#008, FR-012). Null for the normal manual-entry / scan path.
  final String? autoJoinCode;
}
