import 'package:flutter/material.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

class ProductElasticitySelector extends StatelessWidget {
  const ProductElasticitySelector({super.key, required this.selectedElasticity});

  final ValueNotifier<ProductElasticity?> selectedElasticity;

  @override
  Widget build(final BuildContext context) {
    return ValueListenableBuilder<ProductElasticity?>(
      valueListenable: selectedElasticity,
      builder: (final context, final value, final _) =>
          // multiSelectionEnabled + emptySelectionAllowed lets the user toggle
          // off the current selection by tapping it again. In single-mode the
          // tap on the already-selected segment doesn't fire onSelectionChanged.
          SegmentedButton<ProductElasticity>(
            segments: ProductElasticity.values
                .map(
                  (final e) =>
                      ButtonSegment<ProductElasticity>(value: e, label: Text(e.label)),
                )
                .toList(),
            selected: value == null ? <ProductElasticity>{} : <ProductElasticity>{value},
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.zero,
            onSelectionChanged: (final newSet) {
              if (newSet.isEmpty) {
                selectedElasticity.value = null;
              } else if (newSet.length > 1 && value != null) {
                selectedElasticity.value = newSet.firstWhere((final v) => v != value);
              } else {
                selectedElasticity.value = newSet.first;
              }
            },
          ),
    );
  }
}
