import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/theme/app_colors.dart';

/// Minimal static branded splash (#001): logomark on the brand background,
/// then routes to Home. No animation, no logic (FR-002a).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgSubtle,
      body: Center(
        child: SvgPicture.asset(
          'assets/brand/logomark.svg',
          width: 96,
          height: 96,
        ),
      ),
    );
  }
}
