import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProductCategoryFilter extends HookConsumerWidget {
  const ProductCategoryFilter({
    super.key,
    required this.productCategories,
    required this.selectedCategories,
    required this.onCategoryToggle,
  });
  final List<String> productCategories;
  final Set<String> selectedCategories;
  final Function(String) onCategoryToggle;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Wrap(
          spacing: 15,
          runSpacing: 12,
          children: productCategories.map((final category) {
            final isSelected = selectedCategories.contains(category);
            return GestureDetector(
              onTap: () => onCategoryToggle(category),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainer,
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category.substring(0, 1),
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
                    category,
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
