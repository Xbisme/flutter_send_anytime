import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/router/deep_link_coordinator.dart';
import 'package:safe_send/core/services/deeplink/deep_link_service.dart';
import 'package:safe_send/core/services/deeplink/handled_link_store.dart';
import 'package:safe_send/core/services/pairing/active_hosting_registry.dart';

/// Listens for `safesend://` invite links and routes them via
/// [DeepLinkCoordinator] (#008). Mounted via `MaterialApp.router`'s `builder`,
/// so its `context` sits under the navigator + toast overlay yet inside the
/// router — both `context.go` and the app toast work from here.
///
/// Cold start: the launching link is handled once after the first frame, when
/// the router + DI are ready (FR-011). Warm start: the link stream is handled
/// for the app's lifetime (FR-010).
class DeepLinkListener extends StatefulWidget {
  const DeepLinkListener({
    required this.router,
    required this.child,
    super.key,
  });

  /// The app router — navigation goes through this instance directly, since the
  /// builder context this widget runs from sits above the `InheritedGoRouter`.
  final GoRouter router;
  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final DeepLinkService _service = getIt<DeepLinkService>();
  final HandledLinkStore _handledStore = HandledLinkStore();
  late final DeepLinkCoordinator _coordinator = DeepLinkCoordinator(
    getIt<ActiveHostingRegistry>(),
    widget.router,
  );
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _service.links.listen(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _service.getInitialLink();
      if (initial != null) _handle(initial);
    });
  }

  void _handle(Uri uri) {
    // Route only after a frame so the router has finished its first build. iOS
    // delivers the cold-launch URL through the stream *before* the router is
    // initialized; navigating then is silently clobbered by the initial route.
    // scheduleFrame() guarantees the callback fires even if the app is idle.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Skip a link already acted on in a prior run — iOS can redeliver the
      // launch URL on a later cold start, which would otherwise auto-join an
      // expired code and nag with an "expired" toast on every relaunch (#008).
      if (!await _handledStore.claim(uri) || !mounted) return;
      unawaited(_coordinator.handle(context, uri));
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
