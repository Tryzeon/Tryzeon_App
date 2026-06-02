import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

/// Single-select gender picker. Gender is a required attribute (DB NOT NULL,
/// defaults to unisex), so empty selection is not allowed.
class ProductGenderSelector extends StatelessWidget {
  const ProductGenderSelector({super.key, required this.selectedGender});

  final ValueNotifier<ProductGender> selectedGender;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<ProductGender>(
      valueListenable: selectedGender,
      builder: (final context, final value, final _) => SegmentedButton<ProductGender>(
        segments: ProductGender.values
            .map(
              (final g) => ButtonSegment<ProductGender>(value: g, label: Text(g.label)),
            )
            .toList(),
        selected: <ProductGender>{value},
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        onSelectionChanged: (final newSet) => selectedGender.value = newSet.first,
      ),
    );
  }
}
