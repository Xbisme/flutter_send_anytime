import 'package:flutter/widgets.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/transfer/background_transfer_projector.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Additive seam (#011): publishes the active transfer to the
/// [BackgroundTransferCoordinator] for the lifetime of a progress page, and
/// clears it on dispose. Lives in `core/presentation` (not a feature) so it can
/// capture `AppLocalizations` for the surface projection while the coordinator
/// in `core/services` stays l10n-free.
///
/// Attaching for the whole page lifetime is safe: the coordinator only shows a
/// surface while the app is backgrounded AND the transfer is `transferring`,
/// and ends it on terminal/foreground — so this widget needs no phase logic.
class BackgroundTransferBinder extends StatefulWidget {
  const BackgroundTransferBinder({
    required this.views,
    required this.onCancel,
    required this.direction,
    required this.progressRoute,
    required this.peerName,
    required this.child,
    super.key,
  });

  /// The transfer view stream (derived from the cubit — single source of truth).
  final Stream<TransferView> views;

  /// Same cancel path as the in-app Cancel button.
  final VoidCallback onCancel;

  final TransferDirection direction;

  /// `AppRoutes.sendProgress` / `receiveProgress`.
  final String progressRoute;

  /// Peer label shown on the surface (matches the in-app progress screen).
  final String peerName;

  final Widget child;

  @override
  State<BackgroundTransferBinder> createState() =>
      _BackgroundTransferBinderState();
}

class _BackgroundTransferBinderState extends State<BackgroundTransferBinder> {
  BackgroundTransferCoordinator? _coordinator;
  bool _attached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final coordinator = getIt<BackgroundTransferCoordinator>()
      ..attach(
        ActiveTransferHandle(
          views: widget.views,
          direction: widget.direction,
          progressRoute: widget.progressRoute,
          onCancel: widget.onCancel,
          project: (view) => projectBackgroundTransfer(
            l10n: l10n,
            direction: widget.direction,
            peerName: widget.peerName,
            view: view,
            locale: locale,
          ),
        ),
      );
    _coordinator = coordinator;
    _attached = true;
  }

  @override
  void dispose() {
    _coordinator?.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
