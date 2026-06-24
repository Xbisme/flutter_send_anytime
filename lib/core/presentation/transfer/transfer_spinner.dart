import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';

/// A small activity spinner that degrades to a static icon under Reduce Motion
/// (Constitution VI / FR-029).
class TransferSpinner extends StatelessWidget {
  const TransferSpinner({this.size = 18, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final c = AppColors.of(context);
    if (reduceMotion) {
      return Icon(LucideIcons.loader, size: size, color: c.accent);
    }
    return SizedBox(
      width: size,
      height: size,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
