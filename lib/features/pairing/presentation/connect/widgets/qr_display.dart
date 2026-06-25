import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Renders the live pairing [code] as a scannable QR encoding the canonical
/// `safesend://connect?v=1&code=…` payload (#007). While shown, it boosts screen
/// brightness so the code scans reliably, restoring it on dispose (FR-005a).
/// A QR keeps a fixed light background + dark modules in both themes.
class QrDisplay extends StatefulWidget {
  const QrDisplay({required this.code, super.key});

  /// The active 6-digit pairing code (leading zeros preserved).
  final String code;

  @override
  State<QrDisplay> createState() => _QrDisplayState();
}

class _QrDisplayState extends State<QrDisplay> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ScreenBrightness.instance.setApplicationScreenBrightness(1),
    );
  }

  @override
  void dispose() {
    unawaited(ScreenBrightness.instance.resetApplicationScreenBrightness());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      label: l10n.connectQrCodeLabel(widget.code),
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: const BoxDecoration(
            color: AppColors.qrSurfaceLight,
            borderRadius: AppRadii.cardRadius,
          ),
          child: QrImageView(
            data: ConnectLink.build(widget.code),
            size: 220,
            backgroundColor: AppColors.qrSurfaceLight,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.qrModuleDark,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.qrModuleDark,
            ),
          ),
        ),
      ),
    );
  }
}
