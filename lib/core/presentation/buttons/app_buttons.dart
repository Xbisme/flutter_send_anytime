import 'package:flutter/material.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

const _height = 52.0;

/// Primary call-to-action: full-width pill with the brand gradient.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.gradientBrand,
        borderRadius: AppRadii.pillRadius,
        boxShadow: enabled ? AppShadow.accentGlow : null,
      ),
      child: _Content(
        label: label,
        icon: icon,
        color: AppColors.onAccentDark,
      ),
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadii.pillRadius,
            onTap: onPressed,
            child: expanded ? child : IntrinsicWidth(child: child),
          ),
        ),
      ),
    );
  }
}

/// Secondary action: pill with a 2px border, transparent fill.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.pillRadius,
        border: Border.all(color: c.borderStrong, width: 2),
      ),
      child: _Content(label: label, icon: icon, color: c.textPrimary),
    );
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadii.pillRadius,
          onTap: onPressed,
          child: expanded ? child : IntrinsicWidth(child: child),
        ),
      ),
    );
  }
}

/// Destructive action: pill with a 2px danger border + danger text.
/// Reserved — first used by #004/#005 (cancel transfer).
class DangerButton extends StatelessWidget {
  const DangerButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: AppRadii.pillRadius,
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.pillRadius,
              border: Border.all(color: AppColors.danger, width: 2),
            ),
            child: _Content(
              label: label,
              icon: icon,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: AppSpacing.x2),
            ],
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
