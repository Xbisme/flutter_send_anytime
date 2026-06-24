import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_typography.dart';

/// A single mono digit/char cell used for 6-digit pairing codes.
///
/// Reserved component — first used by #003/#005. Built in #001 per FR-017.
class CodeBox extends StatelessWidget {
  const CodeBox({this.value, this.focused = false, super.key});

  final String? value;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 44,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? c.accent : c.accentBorder,
          width: 2,
        ),
      ),
      child: Text(
        value ?? '',
        style: AppTypography.mono(size: 26, color: c.textPrimary),
      ),
    );
  }
}
