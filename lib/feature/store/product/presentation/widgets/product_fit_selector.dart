import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

class ProductFitSelector extends StatelessWidget {
  const ProductFitSelector({super.key, required this.selectedFit});

  final ValueNotifier<ProductFit?> selectedFit;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<ProductFit?>(
      valueListenable: selectedFit,
      builder: (final context, final value, final _) => SegmentedButton<ProductFit>(
        segments: ProductFit.values
            .map((final f) => ButtonSegment<ProductFit>(value: f, label: Text(f.label)))
            .toList(),
        selected: value == null ? <ProductFit>{} : <ProductFit>{value},
        multiSelectionEnabled: true,
        emptySelectionAllowed: true,
        showSelectedIcon: false,
        expandedInsets: EdgeInsets.zero,
        onSelectionChanged: (final newSet) {
          if (newSet.isEmpty) {
            selectedFit.value = null;
          } else if (newSet.length > 1 && value != null) {
            // user added a new segment while one was already selected;
            // keep only the newly added one
            selectedFit.value = newSet.firstWhere((final v) => v != value);
          } else {
            selectedFit.value = newSet.first;
          }
        },
      ),
    );
  }
}
