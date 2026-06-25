import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';

/// Pill progress track with a brand-gradient fill. [value] is 0–1.
class ProgressBar extends StatelessWidget {
  const ProgressBar({required this.value, this.height = 8, super.key});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: c.surfaceSunken),
          FractionallySizedBox(
            widthFactor: clamped,
            child: Container(
              height: height,
              decoration: const BoxDecoration(
                gradient: AppColors.gradientBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
