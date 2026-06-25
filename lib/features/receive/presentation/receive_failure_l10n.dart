import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Maps a transfer/pairing [AppFailure] to a localized, user-facing message for
/// the Receive flow (#005). Lives in the receive feature so it does not import
/// the send or pairing features (Constitution XI); it reuses the shared ARB
/// keys plus the receive-specific ones.
extension ReceiveFailureL10n on AppFailure {
  /// The localized message for this failure on the receive path.
  String receiveMessage(AppLocalizations l10n) => switch (this) {
    AppFailureInvalidCode() => l10n.pairingErrorInvalidCode,
    AppFailureRoomExpired() => l10n.pairingErrorRoomExpired,
    AppFailureRoomFull() => l10n.pairingErrorRoomFull,
    AppFailureRateLimited() => l10n.pairingErrorRateLimited,
    AppFailureSignalingUnreachable() => l10n.pairingErrorUnreachable,
    AppFailureSignalingTimeout() => l10n.pairingErrorTimeout,
    AppFailurePeerUnreachable() => l10n.pairingErrorUnreachable,
    AppFailureConnectionLost() => l10n.receiveErrorConnectionLost,
    AppFailureDataChannelClosed() => l10n.receiveErrorConnectionLost,
    AppFailureIceFailed() => l10n.pairingErrorConnectionLost,
    AppFailureIntegrityCheckFailed() => l10n.receiveErrorIntegrity,
    AppFailureFileWriteFailed() => l10n.receiveErrorWrite,
    AppFailureStorageFull() => l10n.receiveErrorWrite,
    _ => l10n.pairingErrorGeneric,
  };
}
