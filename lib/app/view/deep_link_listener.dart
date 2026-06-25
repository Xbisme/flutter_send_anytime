import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/router/deep_link_coordinator.dart';
import 'package:safe_send/core/services/deeplink/deep_link_service.dart';
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
  const DeepLinkListener({required this.child, super.key});

  final Widget child;

  @override
  State<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends State<DeepLinkListener> {
  final DeepLinkService _service = getIt<DeepLinkService>();
  final DeepLinkCoordinator _coordinator = DeepLinkCoordinator(
    getIt<ActiveHostingRegistry>(),
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
    if (mounted) unawaited(_coordinator.handle(context, uri));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
