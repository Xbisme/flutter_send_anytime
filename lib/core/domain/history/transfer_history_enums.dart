/// Terminal outcome of an agreed-and-started transfer recorded in History
/// (#006, FR-003). Only transfers that were agreed and started reach a record
/// (FR-001) — pairing-stage failures are never recorded.
enum TransferRecordStatus {
  /// Every offered file fully arrived and verified.
  completed,

  /// Some — but not all — offered files completed before an interruption
  /// (FR-013a): the verified files are kept.
  partial,

  /// The transfer failed mid-flight (no completed files kept).
  failed,

  /// The transfer was cancelled by either side (no completed files kept).
  cancelled,
}

/// How the two devices paired for a recorded transfer (FR-007). Only
/// [sixDigitCode] exists today (#003); the rest are reserved so #007–#009 add
/// values without a schema change.
enum PairingMethod {
  /// 6-digit code pairing (#003) — the only method in the MVP.
  sixDigitCode,

  /// QR code pairing (#007).
  qr,

  /// Share-link pairing (#008).
  shareLink,

  /// Nearby-radar pairing (#009).
  nearby,
}
