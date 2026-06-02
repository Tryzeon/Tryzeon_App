import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

/// Single-select garment-type (wardrobe category) picker. This is the product
/// classification used to bridge shop ↔ personal wardrobe.
class ProductWardrobeCategorySelector extends StatelessWidget {
  const ProductWardrobeCategorySelector({
    super.key,
    required this.selectedWardrobeCategory,
    this.onChanged,
  });

  final ValueNotifier<WardrobeCategory?> selectedWardrobeCategory;
  final ValueChanged<WardrobeCategory?>? onChanged;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<WardrobeCategory?>(
      valueListenable: selectedWardrobeCategory,
      builder: (final context, final value, final _) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: WardrobeCategory.values.map((final category) {
          return ChoiceChip(
            label: Text(category.displayName),
            selected: category == value,
            onSelected: (final selected) {
              HapticFeedback.selectionClick();
              final next = selected ? category : null;
              selectedWardrobeCategory.value = next;
              onChanged?.call(next);
            },
          );
        }).toList(),
      ),
    );
  }
}
