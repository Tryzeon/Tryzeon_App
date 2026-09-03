import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryonFab extends StatelessWidget {
  const TryonFab({super.key, required this.onTap, this.size = 24, this.label});

  final VoidCallback onTap;
  final double size;
  final String? label;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.pillAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: label == null
                ? const EdgeInsets.all(AppSpacing.sm)
                : const EdgeInsets.symmetric(
                    horizontal: AppSpacing.smMd,
                    vertical: AppSpacing.sm,
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
                Image.asset(
                  AppConstants.logoMark,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label!,
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
