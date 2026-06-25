import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Localized labels for history enums (#006). Keeps the (de)serializable enum
/// names out of the UI and localization at the display layer (Constitution XIV).
extension TransferRecordStatusL10n on TransferRecordStatus {
  /// The localized status label.
  String label(AppLocalizations l10n) => switch (this) {
    TransferRecordStatus.completed => l10n.historyStatusCompleted,
    TransferRecordStatus.partial => l10n.historyStatusPartial,
    TransferRecordStatus.failed => l10n.historyStatusFailed,
    TransferRecordStatus.cancelled => l10n.historyStatusCancelled,
  };
}

extension PairingMethodL10n on PairingMethod {
  /// The localized pairing-method label.
  String label(AppLocalizations l10n) => switch (this) {
    PairingMethod.sixDigitCode => l10n.historyMethodSixDigit,
    PairingMethod.qr => l10n.historyMethodQr,
    PairingMethod.shareLink => l10n.historyMethodShareLink,
    PairingMethod.nearby => l10n.historyMethodNearby,
  };
}
