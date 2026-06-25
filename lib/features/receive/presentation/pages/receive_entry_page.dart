import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// Screen 04 entry (#005): the receive coordinator. Launched from the Home
/// "Nhận" action, it pushes the shared Connect hub in receiver role; on a
/// successful pairing it hands the open [DataTransport] to the receive progress
/// route. Features never import each other — the handoff is a core-typed
/// navigation payload (Constitution XI).
class ReceiveEntryPage extends StatefulWidget {
  const ReceiveEntryPage({super.key});

  @override
  State<ReceiveEntryPage> createState() => _ReceiveEntryPageState();
}

class _ReceiveEntryPageState extends State<ReceiveEntryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_open()));
  }

  Future<void> _open() async {
    final result = await context.push<ConnectResult>(
      AppRoutes.connect,
      extra: const ConnectRequest(role: TransferRole.receiver),
    );
    if (!mounted) return;
    if (result == null) {
      // Backed out of pairing — leave the receive flow.
      _leave();
      return;
    }
    await context.push<void>(
      AppRoutes.receiveProgress,
      extra: result.transport,
    );
    // The progress screen owns its terminal navigation (Home / restart). If it
    // returned here without navigating, fall back to Home.
    if (mounted) _leave();
  }

  /// Leaves the receive flow. Pops when this page was pushed onto a stack;
  /// otherwise (e.g. reached via "Nhận lại" with `go`, which resets the stack)
  /// there is nothing to pop, so fall back to Home.
  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
