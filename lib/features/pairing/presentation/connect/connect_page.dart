import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/connect_handoff.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/inputs/segmented_tabs.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_body.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_display.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/connect_radar.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:safe_send/features/pairing/presentation/pairing_failure_l10n.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.request.role == TransferRole.sender) {
      unawaited(context.read<PairingCubit>().host());
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
    if (transport != null) {
      context.pop(ConnectResult(transport: transport));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Scaffold(
      body: DecoratedBox(
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
                child: SegmentedTabs(
                  segments: [
                    l10n.connectTabCode,
                    l10n.connectTabQr,
                    l10n.connectTabNearby,
                  ],
                  selectedIndex: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ),
              Expanded(
                child: _tab == 0
                    ? _CodeTab(onConnected: _onConnected)
                    : _ComingSoonTab(message: l10n.connectComingSoonTab),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeTab extends StatelessWidget {
  const _CodeTab({required this.onConnected});

  final VoidCallback onConnected;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PairingCubit, AppState<PairingState>>(
      listenWhen: (_, state) =>
          state is AppLoaded<PairingState> && state.data is PairingConnected,
      listener: (context, _) => onConnected(),
      builder: (context, state) {
        return switch (state) {
          AppError<PairingState>(:final failure) => _FailurePanel(
            failure: failure,
          ),
          AppLoaded<PairingState>(:final data) when data is PairingHosting =>
            _HostingPanel(
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

class _HostingPanel extends StatelessWidget {
  const _HostingPanel({required this.code, required this.remaining});

  final String code;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return FlowBody(
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
            onPressed: null, // stub — #008
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
