import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Maps a transfer/pairing [AppFailure] to a localized, user-facing message for
/// the Send flow (#004). Lives in the send feature so it does not import the
/// pairing feature (Constitution XI); it reuses the shared ARB keys.
extension SendFailureL10n on AppFailure {
  /// The localized message for this failure on the send path.
  String sendMessage(AppLocalizations l10n) => switch (this) {
    AppFailureTransferRejected() => l10n.sendErrorRejected,
    AppFailureFileReadFailed() => l10n.sendErrorFileRead,
    AppFailureConnectionLost() => l10n.pairingErrorConnectionLost,
    AppFailureDataChannelClosed() => l10n.pairingErrorConnectionLost,
    AppFailureRoomExpired() => l10n.pairingErrorRoomExpired,
    AppFailureRoomFull() => l10n.pairingErrorRoomFull,
    AppFailureInvalidCode() => l10n.pairingErrorInvalidCode,
    AppFailureRateLimited() => l10n.pairingErrorRateLimited,
    AppFailureSignalingUnreachable() => l10n.pairingErrorUnreachable,
    AppFailureSignalingTimeout() => l10n.pairingErrorTimeout,
    AppFailurePeerUnreachable() => l10n.pairingErrorUnreachable,
    AppFailureIceFailed() => l10n.pairingErrorConnectionLost,
    AppFailureRelayUnavailable() => l10n.pairingErrorRelayUnavailable,
    _ => l10n.pairingErrorGeneric,
  };
}
