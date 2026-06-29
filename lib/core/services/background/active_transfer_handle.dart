import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';

/// Published by a Send/Receive feature (which has localization context) to the
/// `BackgroundTransferCoordinator` when a transfer enters `transferring`, and
/// cleared on terminal state. This is the additive seam that lets `core/` drive
/// the OS surfaces without importing `features/` (Constitution XI).
///
/// The feature supplies [project] (a closure that captures `AppLocalizations` +
/// locale) so all localization/formatting stays in the presentation layer; the
/// coordinator just forwards `project(view)` to the platform controller.
class ActiveTransferHandle {
  const ActiveTransferHandle({
    required this.views,
    required this.direction,
    required this.progressRoute,
    required this.onCancel,
    required this.project,
    required this.keepOpenTitle,
    required this.keepOpenBody,
  });

  /// The live transfer view stream (derived from the #002 snapshot stream — the
  /// single source of truth). The coordinator renders from this only.
  final Stream<TransferView> views;

  /// Send vs receive.
  final TransferDirection direction;

  /// Where a surface tap returns (`AppRoutes.sendProgress`/`receiveProgress`).
  final String progressRoute;

  /// Invokes the same cancel path as the in-app Cancel button (no confirm when
  /// called from the Android notification action — Clarification 2026-06-27).
  final void Function() onCancel;

  /// Feature-supplied projection (localized + formatted) of a view onto the
  /// surface view model. Keeps l10n out of `core/services`.
  final BackgroundTransferState Function(TransferView view) project;

  /// Localized title/body for the iOS keep-app-open reminder (#011) — built by
  /// the feature (which has l10n) so `core/services` stays l10n-free.
  final String keepOpenTitle;
  final String keepOpenBody;
}
