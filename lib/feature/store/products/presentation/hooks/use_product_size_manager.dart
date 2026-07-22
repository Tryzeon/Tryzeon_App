import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/store/products/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';

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

  /// The full list of sizes the store owner wants to end up with. Working out
  /// which are inserts, updates and deletes is the data layer's job.
  List<SizeItem> toSizeItems() {
    return sizeEntries
        .map((final entry) => entry.toSizeItem(unit: selectedUnit))
        .toList();
  }
  List<NewSizeItem> toNewSizeItems() => toSizeItems().whereType<NewSizeItem>().toList();
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
