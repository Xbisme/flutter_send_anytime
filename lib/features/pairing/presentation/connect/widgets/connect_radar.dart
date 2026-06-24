import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';

/// Radar-ringed phone visual for the Connect "Mã 6 số" tab. Two expanding
/// pulses (`ssRadar`) behind a circular brand avatar. Under Reduce Motion the
/// pulses are static (Constitution VI / FR-029).
class ConnectRadar extends StatefulWidget {
  const ConnectRadar({super.key});

  @override
  State<ConnectRadar> createState() => _ConnectRadarState();
}

class _ConnectRadarState extends State<ConnectRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!reduceMotion) ...[
            _Pulse(_controller, phase: 0),
            _Pulse(_controller, phase: 0.5),
          ],
          const _PhoneAvatar(),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse(this.controller, {required this.phase});

  final AnimationController controller;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value + phase) % 1.0;
        return Opacity(
          opacity: (1 - t) * 0.4,
          child: Container(
            width: 80 + t * 120,
            height: 80 + t * 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.green500.withValues(alpha: 0.28),
            ),
          ),
        );
      },
    );
  }
}

class _PhoneAvatar extends StatelessWidget {
  const _PhoneAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientBrand,
      ),
      child: const Icon(
        LucideIcons.smartphone,
        size: 34,
        color: AppColors.onAccentDark,
      ),
    );
  }
}
