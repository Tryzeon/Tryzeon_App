import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class HomePrimaryActionButton extends StatelessWidget {
  const HomePrimaryActionButton({
    super.key,
    required this.onTap,
    this.isDisabled = false,
    this.label = '虛擬試穿',
    this.icon = Icons.auto_awesome_rounded,
  });

  final VoidCallback? onTap;
  final bool isDisabled;
  final String label;
  final IconData icon;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? AppOpacity.strong : 1.0,
        child: ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: AppOpacity.overlay),
                border: Border.all(
                  color: colorScheme.onPrimary.withValues(alpha: AppOpacity.medium),
                  width: AppStroke.thin,
                ),
                borderRadius: AppRadius.pillAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: colorScheme.primaryContainer),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
