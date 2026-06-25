import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/presentation/transfer/transfer_spinner.dart';
import 'package:safe_send/core/services/permissions/camera_permission_service.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_cubit.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_state.dart';

/// Full-screen QR scanner (#007). Pops the parsed 6-digit code (String) to its
/// caller (the receiver Connect panel), or null on back. Decode/parse/latch is
/// in [QrScanCubit]; the camera controller + its lifecycle live here.
class QrScanPage extends StatelessWidget {
  const QrScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<QrScanCubit>(
      create: (_) {
        final cubit = getIt<QrScanCubit>();
        unawaited(cubit.init());
        return cubit;
      },
      child: const _QrScanView(),
    );
  }
}

class _QrScanView extends StatefulWidget {
  const _QrScanView();

  @override
  State<_QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<_QrScanView> {
  // Created lazily on first camera/analyze use, so a blocked-permission session
  // (pick-from-photo only) never spins up the camera. MobileScanner manages the
  // camera app-lifecycle itself (7.x); dispose releases it (FR-017).
  MobileScannerController? _controller;

  MobileScannerController get _scanner =>
      _controller ??= MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      );

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  void _accept(String code) {
    unawaited(HapticFeedback.mediumImpact());
    context.pop(code);
  }

  void _onDetect(BarcodeCapture capture) {
    final cubit = context.read<QrScanCubit>();
    for (final barcode in capture.barcodes) {
      final outcome = cubit.onDetected(barcode.rawValue);
      switch (outcome) {
        case ScanOutcome.accepted:
          _accept(cubit.acceptedCode!);
          return;
        case ScanOutcome.invalid:
          AppToast.show(
            context,
            context.l10n.scanInvalidCode,
            type: AppToastType.error,
          );
          return;
        case ScanOutcome.ignored:
          break;
      }
    }
  }

  /// US3 — decode a QR from a photo the user already has (FR-011). Reuses the
  /// existing file_picker (image type → no new photo-library permission).
  Future<void> _pickImage() async {
    final cubit = context.read<QrScanCubit>();
    final picked = await FilePicker.pickFiles(type: FileType.image);
    final files = picked?.files ?? const [];
    final path = files.isNotEmpty ? files.first.path : null;
    if (path == null || !mounted) return;
    final capture = await _scanner.analyzeImage(path);
    if (!mounted) return;
    final barcodes = capture?.barcodes ?? const <Barcode>[];
    final raw = barcodes.isNotEmpty ? barcodes.first.rawValue : null;
    if (raw == null) {
      AppToast.show(context, context.l10n.scanNoCodeFound);
      return;
    }
    switch (cubit.onDetected(raw)) {
      case ScanOutcome.accepted:
        _accept(cubit.acceptedCode!);
      case ScanOutcome.invalid:
        AppToast.show(
          context,
          context.l10n.scanInvalidCode,
          type: AppToastType.error,
        );
      case ScanOutcome.ignored:
        break;
    }
  }

  void _toggleTorch() {
    context.read<QrScanCubit>().toggleTorch();
    unawaited(_scanner.toggleTorch());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowAppBar(
              title: l10n.scanTitle,
              leadingIcon: LucideIcons.arrowLeft,
              onLeading: () => context.pop(),
              leadingSemanticLabel: l10n.commonBack,
            ),
            Expanded(
              child: BlocBuilder<QrScanCubit, AppState<QrScanView>>(
                builder: (context, state) {
                  if (state is! AppLoaded<QrScanView>) {
                    return const Center(child: TransferSpinner(size: 28));
                  }
                  final view = state.data;
                  return switch (view.permission) {
                    CameraPermissionStatus.granted => _ScannerSurface(
                      controller: _scanner,
                      torchOn: view.torchOn,
                      onDetect: _onDetect,
                      onToggleTorch: _toggleTorch,
                      onPickImage: _pickImage,
                    ),
                    CameraPermissionStatus.denied => _PermissionPanel(
                      blocked: false,
                      onPrimary: () =>
                          context.read<QrScanCubit>().requestPermission(),
                      onPickImage: _pickImage,
                    ),
                    CameraPermissionStatus.permanentlyDenied ||
                    CameraPermissionStatus.restricted => _PermissionPanel(
                      blocked: true,
                      onPrimary: () =>
                          context.read<QrScanCubit>().openSettings(),
                      onPickImage: _pickImage,
                    ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerSurface extends StatelessWidget {
  const _ScannerSurface({
    required this.controller,
    required this.torchOn,
    required this.onDetect,
    required this.onToggleTorch,
    required this.onPickImage,
  });

  final MobileScannerController controller;
  final bool torchOn;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onToggleTorch;
  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: controller, onDetect: onDetect),
        // Subtle framing + instruction; no animation (Reduce-Motion safe).
        Align(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: c.bgBase.withValues(alpha: 0.9),
                width: 3,
              ),
              borderRadius: AppRadii.cardRadius,
            ),
          ),
        ),
        Positioned(
          left: AppSpacing.x5,
          right: AppSpacing.x5,
          bottom: AppSpacing.x6,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x4,
                  vertical: AppSpacing.x2,
                ),
                decoration: BoxDecoration(
                  color: c.overlay,
                  borderRadius: AppRadii.pillRadius,
                ),
                child: Text(
                  l10n.scanInstruction,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: c.bgBase,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              SecondaryButton(
                label: l10n.scanPickImage,
                icon: LucideIcons.image,
                onPressed: () => unawaited(onPickImage()),
              ),
            ],
          ),
        ),
        Positioned(
          top: AppSpacing.x3,
          right: AppSpacing.x5,
          child: IconButton(
            tooltip: l10n.scanTorch,
            onPressed: onToggleTorch,
            icon: Icon(
              torchOn ? LucideIcons.zap : LucideIcons.zapOff,
              color: c.bgBase,
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionPanel extends StatelessWidget {
  const _PermissionPanel({
    required this.blocked,
    required this.onPrimary,
    required this.onPickImage,
  });

  /// True for permanently-denied / restricted (Open Settings); false for a
  /// re-askable denial (request permission).
  final bool blocked;
  final VoidCallback onPrimary;
  final Future<void> Function() onPickImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.camera, size: 26, color: c.accent),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            l10n.scanCameraBlockedTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            l10n.scanCameraBlockedBody,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.x6),
          PrimaryButton(
            label: blocked ? l10n.scanOpenSettings : l10n.scanRequestPermission,
            icon: blocked ? LucideIcons.settings : LucideIcons.camera,
            onPressed: onPrimary,
          ),
          const SizedBox(height: AppSpacing.x3),
          SecondaryButton(
            label: l10n.scanPickImage,
            icon: LucideIcons.image,
            onPressed: () => unawaited(onPickImage()),
          ),
        ],
      ),
    );
  }
}
