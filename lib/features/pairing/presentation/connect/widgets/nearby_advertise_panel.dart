import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/connect/nearby_advertise_cubit.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/code_display.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/connect_radar.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:uuid/uuid.dart';

/// Sender "Gần đây" tab (#009, US2). A presentation of the SAME hosting session
/// as the 6-digit/QR tabs: it advertises the **live** code over mDNS while shown
/// (no new code/socket — FR-009), shows a discoverable radar + the live code +
/// TTL countdown + a privacy note, and stops on leave/background (FR-005).
class NearbyAdvertisePanel extends StatefulWidget {
  const NearbyAdvertisePanel({super.key});

  @override
  State<NearbyAdvertisePanel> createState() => _NearbyAdvertisePanelState();
}

class _NearbyAdvertisePanelState extends State<NearbyAdvertisePanel>
    with WidgetsBindingObserver {
  final NearbyAdvertiseCubit _cubit = getIt<NearbyAdvertiseCubit>();

  /// A generated default device name until the editable profile lands in #010.
  final String _displayName =
      'Safe Send · ${const Uuid().v4().substring(0, 4).toUpperCase()}';

  String? _advertisedCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The hosting code is usually already live when this tab is opened — the
    // BlocConsumer listener only sees *future* changes, so seed from current.
    final state = context.read<PairingCubit>().state;
    if (state is AppLoaded<PairingState> && state.data is PairingHosting) {
      final code = (state.data as PairingHosting).code.value;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureAdvertising(code),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // FR-005: advertise only while foreground.
    if (state == AppLifecycleState.resumed) {
      final code = _advertisedCode;
      if (code != null) {
        unawaited(_cubit.start(code: code, displayName: _displayName));
      }
    } else {
      unawaited(_cubit.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cubit.close());
    super.dispose();
  }

  void _ensureAdvertising(String code) {
    if (_advertisedCode == code) return;
    _advertisedCode = code;
    unawaited(_cubit.start(code: code, displayName: _displayName));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PairingCubit, AppState<PairingState>>(
        listener: (context, state) {
          if (state is AppLoaded<PairingState> &&
              state.data is PairingHosting) {
            _ensureAdvertising((state.data as PairingHosting).code.value);
          }
        },
        builder: (context, pairing) {
          final hosting =
              pairing is AppLoaded<PairingState> &&
                  pairing.data is PairingHosting
              ? pairing.data as PairingHosting
              : null;
          return BlocBuilder<NearbyAdvertiseCubit, AppState<NearbyAdvertise>>(
            builder: (context, advertise) {
              final data = advertise is AppLoaded<NearbyAdvertise>
                  ? advertise.data
                  : null;
              if (data is NearbyAdvertiseBlocked) {
                return _BlockedView(
                  permanent: data.permanent,
                  onOpenSettings: () => unawaited(_cubit.openSettings()),
                );
              }
              if (hosting == null) {
                return const Center(child: TransferSpinner(size: 28));
              }
              return _AdvertiseView(
                code: hosting.code.value,
                remaining: hosting.code.remaining,
              );
            },
          );
        },
      ),
    );
  }
}

class _AdvertiseView extends StatelessWidget {
  const _AdvertiseView({required this.code, required this.remaining});

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
          const ConnectRadar(),
          const SizedBox(height: AppSpacing.x6),
          Text(
            l10n.nearbyDiscoverableTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
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
          const Spacer(),
          Row(
            children: [
              Icon(LucideIcons.info, size: 14, color: c.textMuted),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  l10n.nearbyPrivacyNote,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  const _BlockedView({required this.permanent, required this.onOpenSettings});

  final bool permanent;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.wifiOff, size: 40, color: c.textMuted),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.nearbyPermissionBlocked,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.nearbyPermissionRationale,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x6),
          if (permanent)
            PrimaryButton(
              label: l10n.nearbyOpenSettings,
              icon: LucideIcons.settings,
              onPressed: onOpenSettings,
            ),
        ],
      ),
    );
  }
}
