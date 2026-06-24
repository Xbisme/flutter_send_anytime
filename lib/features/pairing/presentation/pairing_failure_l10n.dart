import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Maps a pairing/signaling [AppFailure] to a localized, user-facing message
/// (Vietnamese primary, English secondary — FR-023). Reused by the #004 Connect
/// and #005 Receive screens.
extension PairingFailureL10n on AppFailure {
  /// The localized message for this failure.
  String pairingMessage(AppLocalizations l10n) => switch (this) {
    AppFailureInvalidCode() => l10n.pairingErrorInvalidCode,
    AppFailureRoomFull() => l10n.pairingErrorRoomFull,
    AppFailureRoomExpired() => l10n.pairingErrorRoomExpired,
    AppFailureRateLimited() => l10n.pairingErrorRateLimited,
    AppFailureSignalingUnreachable() => l10n.pairingErrorUnreachable,
    AppFailureSignalingTimeout() => l10n.pairingErrorTimeout,
    AppFailureConnectionLost() => l10n.pairingErrorConnectionLost,
    _ => l10n.pairingErrorGeneric,
  };
}
