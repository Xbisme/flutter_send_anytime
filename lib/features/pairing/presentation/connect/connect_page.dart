import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/inputs/segmented_tabs.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_display.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_input.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/connect_radar.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/nearby_advertise_panel.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/nearby_browse_panel.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/qr_display.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:safe_send/features/pairing/presentation/pairing_failure_l10n.dart';
import 'package:share_plus/share_plus.dart';

/// Screen 03 — Kết nối: the shared pairing hub. Functional "Mã 6 số" tab
/// (radar + code + TTL countdown), with QR / Gần đây stubbed for #007/#009.
/// Role-parameterized so #005 reuses it for the receiver. On a successful
/// pairing it pops a [ConnectResult] (the open transport) to its caller.
class ConnectPage extends StatelessWidget {
  const ConnectPage({required this.request, super.key});

  final ConnectRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PairingCubit>(
      create: (_) => getIt<PairingCubit>(),
      child: _ConnectView(request: request),
    );
  }
}

class _ConnectView extends StatefulWidget {
  const _ConnectView({required this.request});

  final ConnectRequest request;

  @override
  State<_ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<_ConnectView> {
  int _tab = 0;
  Timer? _ticker;

  /// Guards the one-shot terminal navigation (connected → handoff, or auto-join
  /// failure → Home) so a trailing state can't trigger a second navigation.
  bool _terminalHandled = false;

  /// How the receiver paired (#007/#008): `qr` when a QR was scanned, `shareLink`
  /// when the device arrived via an invite link, else `sixDigitCode`.
  PairingMethod _receiverMethod = PairingMethod.sixDigitCode;

  /// Sender tapped "Chia sẻ link mời" (#008, US2) — last-action-wins method hint.
  bool _sharedLink = false;

  /// Receiver tapped a nearby device (#009, US1) — a join is in flight; a join
  /// failure shows a toast and keeps the radar usable (FR-017).
  bool _nearbyJoining = false;

  TransferRole get _role => widget.request.role;

  /// The receiver arrived via a share-link invite (#008) — auto-join, no typing.
  bool get _isShareLinkAutoJoin =>
      _role == TransferRole.receiver && widget.request.autoJoinCode != null;

  @override
  void initState() {
    super.initState();
    // Home "Thiết bị gần" lands the receiver straight on the nearby tab (#009).
    if (_role == TransferRole.receiver && widget.request.openNearby) _tab = 1;
    if (_role == TransferRole.sender) {
      unawaited(context.read<PairingCubit>().host());
    } else if (_isShareLinkAutoJoin) {
      // Share-link invite: join the delivered code immediately (#008, FR-012).
      _receiverMethod = PairingMethod.shareLink;
      final code = widget.request.autoJoinCode!;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(context.read<PairingCubit>().joinWithCode(code)),
      );
    }
    // Refresh the expiry countdown once a second.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onConnected() {
    final transport = context.read<PairingCubit>().takeTransport();
    if (transport == null) return;
    context.pop(
      ConnectResult(transport: transport, method: _resolveMethod()),
    );
  }

  /// How this device paired, for the history record (#007/#008). The receiver
  /// tracks its own path; the sender's method is the presentation it was using —
  /// the QR tab being shown wins, else a shared link, else the 6-digit code.
  PairingMethod _resolveMethod() {
    if (_role == TransferRole.receiver) return _receiverMethod;
    if (_tab == 2) return PairingMethod.nearby; // sender "Gần đây" tab (#009).
    if (_tab == 1) return PairingMethod.qr;
    if (_sharedLink) return PairingMethod.shareLink;
    return PairingMethod.sixDigitCode;
  }

  /// Receiver tapped a discovered nearby device (#009, US1) — record the method
  /// and join via the existing code path (no new join logic).
  void _onJoinViaNearby(NearbyDevice device) {
    setState(() {
      _receiverMethod = PairingMethod.nearby;
      _nearbyJoining = true;
    });
    unawaited(context.read<PairingCubit>().joinWithCode(device.code));
  }

  /// Share-link auto-join failed (expired/invalid code) → toast + Home, rather
  /// than the manual-entry inline retry (#008, FR-013).
  void _onAutoJoinFailed() {
    AppToast.show(
      context,
      context.l10n.shareLinkExpired,
      type: AppToastType.error,
    );
    context.go(AppRoutes.home);
  }

  /// Receiver scanned a QR (#007) — remember the method, then join via the
  /// existing code path (no new join logic).
  void _onJoinViaQr(String code) {
    setState(() => _receiverMethod = PairingMethod.qr);
    unawaited(context.read<PairingCubit>().joinWithCode(code));
  }

  /// Sender shared the invite link (#008, US2) — record the method (last-action
  /// -wins) so this session is tagged `shareLink` if the peer joins via it.
  void _onSharedLink() => setState(() => _sharedLink = true);

  Widget _buildTab() {
    final l10n = context.l10n;
    if (_tab == 0) {
      return _CodeTab(
        role: _role,
        onJoinViaQr: _onJoinViaQr,
        onSharedLink: _onSharedLink,
        openScanner: widget.request.openScanner,
      );
    }
    // Sender QR tab (a presentation of the SAME hosting session — no new code).
    if (_role == TransferRole.sender && _tab == 1) {
      return const _SenderQrPanel();
    }
    // Receiver "Gần đây" tab (#009, US1): browse + tap a nearby sender.
    if (_role == TransferRole.receiver && _tab == 1) {
      return NearbyBrowsePanel(onJoin: _onJoinViaNearby);
    }
    // Sender "Gần đây" tab (#009, US2): advertise the live hosting code.
    if (_role == TransferRole.sender && _tab == 2) {
      return const NearbyAdvertisePanel();
    }
    return _ComingSoonTab(message: l10n.connectComingSoonTab);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Scaffold(
      // One connection listener for every tab (incl. the QR tab), so pairing
      // pops the result no matter which presentation the sender is viewing.
      body: BlocListener<PairingCubit, AppState<PairingState>>(
        listenWhen: (_, state) =>
            (state is AppLoaded<PairingState> &&
                state.data is PairingConnected) ||
            (state is AppError<PairingState> &&
                (_isShareLinkAutoJoin || _nearbyJoining)),
        listener: (_, state) {
          if (state is AppError<PairingState>) {
            // A failed join: share-link auto-join → toast + Home (FR-013);
            // a nearby tap → toast, stay on the radar (FR-017).
            if (_isShareLinkAutoJoin) {
              if (_terminalHandled) return;
              _terminalHandled = true;
              _onAutoJoinFailed();
            } else if (_nearbyJoining) {
              setState(() => _nearbyJoining = false);
              AppToast.show(
                context,
                context.l10n.nearbyStaleToast,
                type: AppToastType.error,
              );
            }
            return;
          }
          if (_terminalHandled) return;
          _terminalHandled = true;
          _onConnected();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppColors.green500.withValues(alpha: 0.10),
                c.bgSubtle,
              ],
              radius: 0.9,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                FlowAppBar(
                  title: l10n.connectTitle,
                  leadingIcon: LucideIcons.x,
                  onLeading: () => context.pop(),
                  leadingSemanticLabel: l10n.commonBack,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x5,
                  ),
                  child: SegmentedTabs(
                    // QR is sender-only — the receiver scans via the button inside
                    // the code tab, not a tab of its own (#007, FR-001).
                    segments: _role == TransferRole.receiver
                        ? [l10n.connectTabCode, l10n.connectTabNearby]
                        : [
                            l10n.connectTabCode,
                            l10n.connectTabQr,
                            l10n.connectTabNearby,
                          ],
                    selectedIndex: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(child: _buildTab()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeTab extends StatelessWidget {
  const _CodeTab({
    required this.role,
    required this.onJoinViaQr,
    required this.onSharedLink,
    required this.openScanner,
  });

  final TransferRole role;
  final void Function(String code) onJoinViaQr;
  final VoidCallback onSharedLink;
  final bool openScanner;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PairingCubit, AppState<PairingState>>(
      builder: (context, state) {
        // Receiver: a code-entry panel that keeps the entered code on failure
        // (FR-023). The sender path issues + displays a code instead.
        if (role == TransferRole.receiver) {
          return _ReceiverPanel(
            state: state,
            onJoinViaQr: onJoinViaQr,
            openScanner: openScanner,
          );
        }
        return switch (state) {
          AppError<PairingState>(:final failure) => _FailurePanel(
            failure: failure,
          ),
          AppLoaded<PairingState>(:final data) when data is PairingHosting =>
            _HostingPanel(
              code: data.code.value,
              remaining: data.code.remaining,
              onShared: onSharedLink,
            ),
          AppLoaded<PairingState>(:final data) when data is PairingFailed =>
            _FailurePanel(failure: data.failure),
          _ => const _ConnectingPanel(),
        };
      },
    );
  }
}

/// Receiver code-entry panel (#005, US3). Owns the entered code so it survives
/// rebuilds across a recoverable failure; submits via [PairingCubit.joinWithCode].
class _ReceiverPanel extends StatefulWidget {
  const _ReceiverPanel({
    required this.state,
    required this.onJoinViaQr,
    required this.openScanner,
  });

  final AppState<PairingState> state;
  final void Function(String code) onJoinViaQr;
  final bool openScanner;

  @override
  State<_ReceiverPanel> createState() => _ReceiverPanelState();
}

class _ReceiverPanelState extends State<_ReceiverPanel> {
  String _code = '';

  @override
  void initState() {
    super.initState();
    // Home "Quét QR" lands the receiver straight on the scanner (#007, FR-019).
    if (widget.openScanner) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openScanner());
    }
  }

  /// Open the full-screen scanner; a returned code joins via the parent.
  Future<void> _openScanner() async {
    final code = await context.push<String>(AppRoutes.qrScan);
    if (code != null && mounted) widget.onJoinViaQr(code);
  }

  bool get _isJoining {
    final state = widget.state;
    return state is AppLoading<PairingState> ||
        (state is AppLoaded<PairingState> &&
            (state.data is PairingConnecting ||
                state.data is PairingJoining ||
                state.data is PairingPeerPresent ||
                state.data is PairingConnected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    final state = widget.state;
    final failure = state is AppError<PairingState> ? state.failure : null;
    final canConnect = _code.length == 6 && !_isJoining;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          const Spacer(),
          Text(
            l10n.receiveEnterCodeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.receiveEnterCodeInstruction,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x6),
          CodeInput(
            semanticLabel: l10n.receiveEnterCodeTitle,
            onChanged: (v) => setState(() => _code = v),
          ),
          const SizedBox(height: AppSpacing.x4),
          if (failure != null)
            Text(
              failure.pairingMessage(l10n),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          const Spacer(),
          if (_isJoining)
            const TransferSpinner(size: 28)
          else ...[
            PrimaryButton(
              label: l10n.receiveConnect,
              icon: LucideIcons.arrowRight,
              onPressed: canConnect
                  ? () => unawaited(
                      context.read<PairingCubit>().joinWithCode(_code),
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.x4),
            Row(
              children: [
                Expanded(child: Divider(color: c.borderSubtle)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x3,
                  ),
                  child: Text(
                    l10n.commonOr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: c.borderSubtle)),
              ],
            ),
            const SizedBox(height: AppSpacing.x4),
            // Scan the sender's QR instead of typing the code (#007). Stays
            // available after a failure so an expired scan can be re-tried.
            SecondaryButton(
              label: l10n.receiveScanQr,
              icon: LucideIcons.qrCode,
              onPressed: () => unawaited(_openScanner()),
            ),
          ],
        ],
      ),
    );
  }
}

class _HostingPanel extends StatelessWidget {
  const _HostingPanel({
    required this.code,
    required this.remaining,
    required this.onShared,
  });

  final String code;
  final Duration remaining;

  /// Called when the user shares the invite link (#008, US2) so the session is
  /// recorded as `shareLink`.
  final VoidCallback onShared;

  /// Build the invite link for the live code and hand it to the system share
  /// sheet (#008, FR-001/FR-005). Reads the live code only — no new code/socket.
  Future<void> _share(BuildContext context) async {
    onShared();
    final link = ConnectLink.build(code);
    await SharePlus.instance.share(
      ShareParams(text: '${context.l10n.connectShareLinkMessage}\n$link'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          const Spacer(),
          const ConnectRadar(),
          const SizedBox(height: AppSpacing.x6),
          Text(
            l10n.connectShareInstruction,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x4),
          CodeDisplay(code: code),
          const SizedBox(height: AppSpacing.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.clock, size: 15, color: c.textMuted),
              const SizedBox(width: AppSpacing.x2),
              Text(
                l10n.connectExpiresIn(Formatters.clock(remaining)),
                style: AppTypography.mono(size: 13, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.connectWaiting,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          const Spacer(),
          SecondaryButton(
            label: l10n.connectShareLink,
            icon: LucideIcons.share2,
            onPressed: () => unawaited(_share(context)),
          ),
        ],
      ),
    );
  }
}

class _ConnectingPanel extends StatelessWidget {
  const _ConnectingPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TransferSpinner(size: 28),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.connectWaiting,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.failure});

  final AppFailure failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 40,
            color: AppColors.danger,
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            failure.pairingMessage(l10n),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: c.textPrimary),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: l10n.connectRefreshCode,
            icon: LucideIcons.refreshCw,
            onPressed: () => unawaited(context.read<PairingCubit>().host()),
          ),
          const SizedBox(height: AppSpacing.x3),
          SecondaryButton(
            label: l10n.commonBack,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

/// Sender QR tab (#007). A second presentation of the SAME hosting session as
/// the 6-digit tab — it reads the live [PairingHosting] state and never issues a
/// new code or opens a second socket (FR-004).
class _SenderQrPanel extends StatelessWidget {
  const _SenderQrPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PairingCubit, AppState<PairingState>>(
      builder: (context, state) {
        return switch (state) {
          AppError<PairingState>(:final failure) => _FailurePanel(
            failure: failure,
          ),
          AppLoaded<PairingState>(:final data) when data is PairingHosting =>
            _QrHostingPanel(
              code: data.code.value,
              remaining: data.code.remaining,
            ),
          AppLoaded<PairingState>(:final data) when data is PairingFailed =>
            _FailurePanel(failure: data.failure),
          _ => const _ConnectingPanel(),
        };
      },
    );
  }
}

class _QrHostingPanel extends StatelessWidget {
  const _QrHostingPanel({required this.code, required this.remaining});

  final String code;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        children: [
          const Spacer(),
          QrDisplay(code: code),
          const SizedBox(height: AppSpacing.x5),
          Text(
            l10n.connectQrInstruction,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x4),
          CodeDisplay(code: code),
          const SizedBox(height: AppSpacing.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.clock, size: 15, color: c.textMuted),
              const SizedBox(width: AppSpacing.x2),
              Text(
                l10n.connectExpiresIn(Formatters.clock(remaining)),
                style: AppTypography.mono(size: 13, color: c.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.connectWaiting,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.textMuted),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 30, color: c.textMuted),
            const SizedBox(height: AppSpacing.x3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
