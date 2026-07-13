import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/store/products/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';

class ProductSizeDeltas {
  const ProductSizeDeltas({
    required this.sizesToAdd,
    required this.sizesToUpdate,
    required this.sizeIdsToDelete,
  });

  final List<CreateProductSizeParams> sizesToAdd;
  final List<ProductSize> sizesToUpdate;
  final List<String> sizeIdsToDelete;
}

class ProductSizeManager {
  ProductSizeManager({
    required this.sizeEntries,
    required this.selectedUnit,
    required this.addSize,
    required this.removeSize,
    required this.changeUnit,
    required this.appendParsedSizes,
  });

  final List<ProductSizeEntryController> sizeEntries;
  final MeasurementUnit selectedUnit;
  final VoidCallback addSize;
  final void Function(int index) removeSize;
  final void Function(MeasurementUnit unit) changeUnit;
  final void Function(List<ParsedSize> parsed) appendParsedSizes;

  List<CreateProductSizeParams> toCreateProductSizeParams() {
    return sizeEntries
        .map((final entry) => entry.toCreateProductSizeParams(unit: selectedUnit))
        .toList();
  }

  ProductSizeDeltas calculateDeltas(
    final String productId,
    final List<ProductSize>? originalSizes,
  ) {
    final originalSizeIds = originalSizes?.map((final s) => s.id).toSet() ?? {};
    final sizesToAdd = <CreateProductSizeParams>[];
    final sizesToUpdate = <ProductSize>[];
    final targetSizeIds = <String>{};

    for (final entry in sizeEntries) {
      if (entry.id == null) {
        sizesToAdd.add(entry.toCreateProductSizeParams(unit: selectedUnit));
      } else {
        targetSizeIds.add(entry.id!);

        final originalSize = originalSizes
            ?.where((final s) => s.id == entry.id)
            .firstOrNull;

        if (originalSize != null) {
          final updatedSize = entry.toProductSize(productId, unit: selectedUnit);

          if (originalSize != updatedSize) {
            sizesToUpdate.add(updatedSize);
          }
        }
      }
    }

    final sizeIdsToDelete = originalSizeIds.difference(targetSizeIds).toList();

    return ProductSizeDeltas(
      sizesToAdd: sizesToAdd,
      sizesToUpdate: sizesToUpdate,
      sizeIdsToDelete: sizeIdsToDelete,
    );
  }
}

ProductSizeManager useProductSizeManager({final List<ProductSize>? initialSizes}) {
  final sizeEntries = useState<List<ProductSizeEntryController>>([]);
  final selectedUnit = useState(MeasurementUnit.centimeter);

  // Initialize size entries from existing product
  useEffect(() {
    if (initialSizes != null && initialSizes.isNotEmpty) {
      final entries = initialSizes
          .map(ProductSizeEntryController.fromProductSize)
          .toList();
      sizeEntries.value = entries;
    }

    return () {
      for (final entry in sizeEntries.value) {
        entry.dispose();
      }
    };
  }, const []);

  void addSize() {
    sizeEntries.value = [...sizeEntries.value, ProductSizeEntryController()];
  }

  void removeSize(final int index) {
    if (index < 0 || index >= sizeEntries.value.length) return;
    sizeEntries.value[index].dispose();
    final newList = [...sizeEntries.value];
    newList.removeAt(index);
    sizeEntries.value = newList;
  }

  void changeUnit(final MeasurementUnit newUnit) {
    final oldUnit = selectedUnit.value;
    selectedUnit.value = newUnit;

    for (final entry in sizeEntries.value) {
      entry.convertValues(fromUnit: oldUnit, toUnit: newUnit);
    }
  }

  void appendParsedSizes(final List<ParsedSize> parsed) {
    if (parsed.isEmpty) return;
    final added = parsed
        .map(
          (final p) => ProductSizeEntryController.fromParsedSize(
            p,
            targetUnit: selectedUnit.value,
          ),
        )
        .toList();
    sizeEntries.value = [...sizeEntries.value, ...added];
  }

  return ProductSizeManager(
    sizeEntries: sizeEntries.value,
    selectedUnit: selectedUnit.value,
    addSize: addSize,
    removeSize: removeSize,
    changeUnit: changeUnit,
    appendParsedSizes: appendParsedSizes,
  );
}
