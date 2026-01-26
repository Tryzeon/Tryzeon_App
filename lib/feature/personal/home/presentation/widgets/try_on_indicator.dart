import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentTryonIndex == -1)
              Text(
                '原圖',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: colorScheme.surface.withValues(alpha: 0.45),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tryonImagesCount, (final index) {
                  final isSelected = currentTryonIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
