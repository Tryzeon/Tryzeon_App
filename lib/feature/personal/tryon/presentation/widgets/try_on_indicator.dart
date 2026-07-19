import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class TryOnIndicator extends StatelessWidget {
  const TryOnIndicator({
    super.key,
    required this.currentTryonIndex,
    required this.tryonImagesCount,
  });

  final int currentTryonIndex;
  final int tryonImagesCount;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(tryonImagesCount, (final index) {
        final isSelected = currentTryonIndex == index;
        return AnimatedContainer(
          duration: AppDuration.slow,
          curve: AppCurves.standard,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          width: isSelected ? 20.0 : 12.0,
          height: 2.0,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onPrimary.withValues(alpha: AppOpacity.strong),
            borderRadius: AppRadius.pillAll,
          ),
        );
      }),
    );
  }
}
