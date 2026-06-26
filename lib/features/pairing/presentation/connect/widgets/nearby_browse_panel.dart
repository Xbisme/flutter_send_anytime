import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/nearby_device.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/connect/nearby_discovery_cubit.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/connect_radar.dart';
import 'package:safe_send/features/pairing/presentation/connect/widgets/nearby_device_row.dart';

/// Receiver "Gần đây" tab (#009, US1): browses nearby advertising senders and
/// lists them as tappable [NearbyDeviceRow]s. Advertising/browsing is tied to
/// this widget being mounted + the app foreground (FR-005). Tapping a device
/// hands its code up via [onJoin] to the existing join path.
class NearbyBrowsePanel extends StatefulWidget {
  const NearbyBrowsePanel({required this.onJoin, super.key});

  /// Called with the tapped device so the Connect hub joins its code.
  final void Function(NearbyDevice device) onJoin;

  @override
  State<NearbyBrowsePanel> createState() => _NearbyBrowsePanelState();
}

class _NearbyBrowsePanelState extends State<NearbyBrowsePanel>
    with WidgetsBindingObserver {
  final NearbyDiscoveryCubit _cubit = getIt<NearbyDiscoveryCubit>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_cubit.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // FR-005: browse only while foreground; stop otherwise.
    if (state == AppLifecycleState.resumed) {
      unawaited(_cubit.start());
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<NearbyDiscoveryCubit, AppState<NearbyBrowse>>(
        builder: (context, state) => switch (state) {
          AppLoaded<NearbyBrowse>(:final data) => switch (data) {
            NearbyBrowseBlocked(:final permanent) => _BlockedView(
              permanent: permanent,
              onOpenSettings: () => unawaited(_cubit.openSettings()),
            ),
            NearbyBrowsing(:final devices) => _BrowsingView(
              devices: devices,
              onJoin: widget.onJoin,
            ),
          },
          AppError<NearbyBrowse>() => const _BrowsingView(
            devices: [],
            onJoin: _noop,
          ),
          _ => const Center(child: TransferSpinner(size: 28)),
        },
      ),
    );
  }

  static void _noop(NearbyDevice _) {}
}

class _BrowsingView extends StatelessWidget {
  const _BrowsingView({required this.devices, required this.onJoin});

  final List<NearbyDevice> devices;
  final void Function(NearbyDevice device) onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x2),
          const Center(child: ConnectRadar()),
          const SizedBox(height: AppSpacing.x5),
          Text(
            l10n.nearbySectionTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          Expanded(
            child: devices.isEmpty
                ? _EmptyView()
                : ListView.separated(
                    itemCount: devices.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.x3),
                    itemBuilder: (_, i) => NearbyDeviceRow(
                      device: devices[i],
                      onTap: () => onJoin(devices[i]),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.x3),
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

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.radar, size: 36, color: c.textMuted),
          const SizedBox(height: AppSpacing.x3),
          Text(
            l10n.nearbyEmptyTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.nearbyEmptyHint,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
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
