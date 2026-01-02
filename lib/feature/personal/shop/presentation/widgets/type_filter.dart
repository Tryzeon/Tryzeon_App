import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ProductTypeFilter extends HookWidget {
  const ProductTypeFilter({
    super.key,
    required this.productTypes,
    required this.selectedTypes,
    required this.onTypeToggle,
  });
  final List<String> productTypes;
  final Set<String> selectedTypes;
  final Function(String) onTypeToggle;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 15,
          runSpacing: 12,
          children: productTypes.map((final type) {
            final isSelected = selectedTypes.contains(type);
            return GestureDetector(
              onTap: () => onTypeToggle(type),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [colorScheme.primary, colorScheme.secondary],
                            )
                          : null,
                      color: isSelected ? null : colorScheme.surfaceContainer,
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        type.substring(0, 1),
                        style: textTheme.headlineMedium?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
