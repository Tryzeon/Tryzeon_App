import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/standard_size_label.dart';
import 'package:tryzeon/feature/store/products/domain/entities/parsed_size.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';

class ProductSizeManager {
  ProductSizeManager({
    required this.sizeEntries,
    required this.selectedUnit,
    required this.toggleStandard,
    required this.addCustom,
    required this.removeLabel,
    required this.changeUnit,
    required this.applyParsedSizes,
  });

  final List<ProductSizeEntryController> sizeEntries;
  final MeasurementUnit selectedUnit;

  final void Function(StandardSizeLabel label) toggleStandard;
  final void Function(String name) addCustom;
  final void Function(String label) removeLabel;
  final void Function(MeasurementUnit unit) changeUnit;
  final void Function(List<ParsedSize> parsed) applyParsedSizes;

  bool hasLabel(final String label) {
    final key = StandardSizeLabel.matchKeyOf(label);
    return sizeEntries.any((final e) => e.matchKey == key);
  }

  bool isSelected(final StandardSizeLabel label) => hasLabel(label.display);

  /// 這件商品自己新增的尺碼，照列的順序。
  List<String> get customLabels => sizeEntries
      .where((final e) => StandardSizeLabel.tryParse(e.label) == null)
      .map((final e) => e.label)
      .toList();

  /// The full list of sizes the store owner wants to end up with. Working out
  /// which are inserts, updates and deletes is the data layer's job.
  /// [visibleTypes] mirrors what the editor showed; hidden dimensions are dropped.
  List<SizeItem> toSizeItems({required final List<GarmentMeasurementType> visibleTypes}) {
    return sizeEntries
        .map(
          (final entry) =>
              entry.toSizeItem(unit: selectedUnit, visibleTypes: visibleTypes),
        )
        .toList();
  }

  List<NewSizeItem> toNewSizeItems({
    required final List<GarmentMeasurementType> visibleTypes,
  }) => toSizeItems(visibleTypes: visibleTypes).whereType<NewSizeItem>().toList();
}

ProductSizeManager useProductSizeManager({final List<ProductSize>? initialSizes}) {
  final sizeEntries = useState<List<ProductSizeEntryController>>([]);
  final selectedUnit = useState(MeasurementUnit.centimeter);

  ProductSizeEntryController? findByLabel(final String label) {
    final key = StandardSizeLabel.matchKeyOf(label);
    for (final entry in sizeEntries.value) {
      if (entry.matchKey == key) return entry;
    }
    return null;
  }

  void insertEntry(final ProductSizeEntryController entry) {
    final list = [...sizeEntries.value];
    final index = sizeRowInsertIndex(
      list.map((final e) => e.label).toList(),
      entry.label,
    );
    list.insert(index, entry);
    sizeEntries.value = list;
  }

  useEffect(() {
    for (final size in initialSizes ?? const <ProductSize>[]) {
      insertEntry(ProductSizeEntryController.fromProductSize(size));
    }

    return () {
      for (final entry in sizeEntries.value) {
        entry.dispose();
      }
    };
  }, const []);

  void addLabel(final String label) {
    if (findByLabel(label) != null) return;
    insertEntry(ProductSizeEntryController(label: label));
  }

  void removeLabel(final String label) {
    final entry = findByLabel(label);
    if (entry == null) return;
    entry.dispose();
    sizeEntries.value = [...sizeEntries.value]..remove(entry);
  }

  void toggleStandard(final StandardSizeLabel label) {
    if (findByLabel(label.display) != null) {
      removeLabel(label.display);
    } else {
      addLabel(label.display);
    }
  }

  void addCustom(final String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    addLabel(StandardSizeLabel.tryParse(trimmed)?.display ?? trimmed);
  }

  void changeUnit(final MeasurementUnit newUnit) {
    final oldUnit = selectedUnit.value;
    selectedUnit.value = newUnit;

    for (final entry in sizeEntries.value) {
      entry.convertValues(fromUnit: oldUnit, toUnit: newUnit);
    }
  }

  void applyParsedSizes(final List<ParsedSize> parsed) {
    for (final p in parsed) {
      final label = StandardSizeLabel.tryParse(p.name)?.display ?? p.name.trim();
      if (label.isEmpty) continue;
      var entry = findByLabel(label);
      if (entry == null) {
        entry = ProductSizeEntryController(label: label);
        insertEntry(entry);
      }
      entry.applyParsed(p, targetUnit: selectedUnit.value);
    }
  }

  return ProductSizeManager(
    sizeEntries: sizeEntries.value,
    selectedUnit: selectedUnit.value,
    toggleStandard: toggleStandard,
    addCustom: addCustom,
    removeLabel: removeLabel,
    changeUnit: changeUnit,
    applyParsedSizes: applyParsedSizes,
  );
}
