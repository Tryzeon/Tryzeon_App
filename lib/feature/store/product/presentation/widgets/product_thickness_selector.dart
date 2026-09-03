import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

class ProductThicknessSelector extends StatelessWidget {
  const ProductThicknessSelector({super.key, required this.selectedThickness});

  final ValueNotifier<ProductThickness?> selectedThickness;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<ProductThickness?>(
      valueListenable: selectedThickness,
      builder: (final context, final value, final _) =>
          // multiSelectionEnabled + emptySelectionAllowed lets the user toggle
          // off the current selection by tapping it again. In single-mode the
          // tap on the already-selected segment doesn't fire onSelectionChanged.
          SegmentedButton<ProductThickness>(
            segments: ProductThickness.values
                .map(
                  (final t) =>
                      ButtonSegment<ProductThickness>(value: t, label: Text(t.label)),
                )
                .toList(),
            selected: value == null ? <ProductThickness>{} : <ProductThickness>{value},
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (final newSet) {
              if (newSet.isEmpty) {
                selectedThickness.value = null;
              } else if (newSet.length > 1 && value != null) {
                selectedThickness.value = newSet.firstWhere((final v) => v != value);
              } else {
                selectedThickness.value = newSet.first;
              }
            },
          ),
    );
  }
}
