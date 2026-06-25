import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';

/// Turns a delivered `safesend://` invite link into a routing decision (#008).
///
/// Core-pure: it navigates by [AppRoutes] constants + the core-typed
/// [ReceiveEntryRequest] extra and surfaces messages via [AppToast] — it imports
/// no feature pages (Constitution XI). It never logs the code or the URL; the
/// payload carries the rendezvous secret (Constitution I).
class DeepLinkCoordinator {
  const DeepLinkCoordinator(this._hosting);

  final ActiveHostingRegistry _hosting;

  /// Handle one incoming [uri], using [context] for navigation and toasts.
  /// The caller delivers links one at a time (cold via the initial link, warm
  /// via the stream), so the most recent link is the one acted upon (FR-016).
  Future<void> handle(BuildContext context, Uri uri) async {
    final l10n = context.l10n;
    final parsed = ConnectLink.parse(uri.toString());
    switch (parsed) {
      case Failure<String>():
        // Malformed / not a Safe Send invite → toast + Home (FR-013).
        AppToast.show(context, l10n.shareLinkInvalid, type: AppToastType.error);
        context.go(AppRoutes.home);
      case Success<String>(:final value):
        // Self-invite: the host tapped its own live link (FR-015).
        if (value == _hosting.activeHostingCode) {
          AppToast.show(context, l10n.shareLinkOwn);
          return;
        }
        // Opened during an active transfer → confirm before leaving it; never
        // silently abandon a running transfer (FR-014).
        if (_inTransfer(context)) {
          final leave = await _confirmLeaveTransfer(context);
          if (!leave || !context.mounted) return;
        }
        // Route into Receive and auto-join the delivered code (FR-012). A
        // valid-but-expired code is rejected later by the join path (FR-013).
        context.go(
          AppRoutes.receive,
          extra: ReceiveEntryRequest(autoJoinCode: value),
        );
    }
  }

  /// Whether a transfer is currently on screen (the send/receive progress
  /// route) — the router is the source of truth for "what screen am I on".
  bool _inTransfer(BuildContext context) {
    final path = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration.uri.path;
    return path == AppRoutes.sendProgress || path == AppRoutes.receiveProgress;
  }

  Future<bool> _confirmLeaveTransfer(BuildContext context) async {
    final l10n = context.l10n;
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: Text(l10n.shareLinkLeaveTransferTitle),
        content: Text(l10n.shareLinkLeaveTransferBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.shareLinkLeaveTransferCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.shareLinkLeaveTransferConfirm),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
