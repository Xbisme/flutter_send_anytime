import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';

/// App bar for full-screen flow screens: a 40px circular leading button
/// (back/close) + title. Used by Send/Receive and later pairing flows.
class FlowAppBar extends StatelessWidget {
  const FlowAppBar({
    required this.title,
    required this.onLeading,
    this.leadingIcon,
    this.leadingSemanticLabel,
    super.key,
  });

  final String title;
  final VoidCallback onLeading;
  final IconData? leadingIcon;
  final String? leadingSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x2,
        AppSpacing.x5,
        AppSpacing.x4,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: leadingSemanticLabel,
            child: InkResponse(
              onTap: onLeading,
              radius: 28,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon ?? LucideIcons.arrowLeft,
                  size: 19,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}
