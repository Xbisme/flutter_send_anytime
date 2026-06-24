import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// Settings-style row: leading icon tile + label/subtitle + trailing switch.
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onChanged,
    this.showDivider = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: showDivider
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(color: c.borderSubtle),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3 + 2),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.accentSubtle,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: c.accent),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: c.accent,
          ),
        ],
      ),
    );
  }
}
