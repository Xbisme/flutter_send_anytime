import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// Projects a [TransferView] (the in-app source of truth) onto a localized,
/// display-ready [BackgroundTransferState] for the OS surfaces. Lives in
/// `core/presentation` because it needs `AppLocalizations` + [Formatters];
/// the background coordinator (in `core/services`) stays l10n-free and receives
/// this as the `project` closure on an `ActiveTransferHandle`.
///
/// Reusing [Formatters] (the same helpers the in-app progress screen uses)
/// keeps the surface numbers identical to the in-app screen (FR-006).
BackgroundTransferState projectBackgroundTransfer({
  required AppLocalizations l10n,
  required TransferDirection direction,
  required String peerName,
  required TransferView view,
  String? locale,
}) {
  final isSend = direction == TransferDirection.sent;
  final percent = (view.overallProgress * 100).round().clamp(0, 100);
  final eta = view.etaSeconds;
  return BackgroundTransferState(
    direction: direction,
    peerName: peerName,
    fileCount: view.fileCount,
    phase: mapBackgroundPhase(view.phase),
    percent: percent,
    title: isSend
        ? l10n.bgSendingTitle(view.fileCount)
        : l10n.bgReceivingTitle(view.fileCount),
    peerLine: isSend ? l10n.bgToPeer(peerName) : l10n.bgFromPeer(peerName),
    speedLabel: Formatters.speed(view.speedBytesPerSec, locale: locale),
    bytesLabel:
        '${Formatters.bytes(view.bytesDone, locale: locale)} / '
        '${Formatters.bytes(view.bytesTotal, locale: locale)}',
    etaLabel: eta == null
        ? ''
        : l10n.bgEta(Formatters.clock(Duration(seconds: eta))),
    cancelLabel: l10n.bgCancel,
  );
}
