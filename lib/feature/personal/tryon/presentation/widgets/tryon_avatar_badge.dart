import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Persistent state feedback, so the toggle action in the more-options sheet
/// can stay silent.
class TryonAvatarBadge extends StatelessWidget {
  const TryonAvatarBadge({super.key, required this.isVisible});

  final bool isVisible;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: AppDuration.standard,
      curve: AppCurves.emphasized,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.star_rounded, color: colorScheme.onPrimary, size: 20),
      ),
    );
  }
}
