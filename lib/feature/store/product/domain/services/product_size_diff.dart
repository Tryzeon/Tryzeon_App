import 'package:tryzeon/feature/store/product/domain/entities/product.dart';
import 'package:tryzeon/feature/store/product/domain/value_objects/size_item.dart';

/// A size row that changed, paired with the row it started from so the caller
/// can write only the columns that actually differ.
class ProductSizeUpdate {
  const ProductSizeUpdate({required this.original, required this.target});

  final ProductSize original;
  final ExistingSizeItem target;
}

/// What has to happen to a product's size rows to match the store owner's form.
class ProductSizeDiff {
  const ProductSizeDiff({
    required this.toAdd,
    required this.toUpdate,
    required this.idsToDelete,
  });

  final List<NewSizeItem> toAdd;
  final List<ProductSizeUpdate> toUpdate;
  final List<String> idsToDelete;

  bool get isEmpty => toAdd.isEmpty && toUpdate.isEmpty && idsToDelete.isEmpty;
}

/// Diffs the [target] sizes the store owner wants against the product's
/// [original] rows.
///
/// An [ExistingSizeItem] whose row is no longer there is skipped rather than
/// re-inserted: the row was deleted elsewhere, and inserting it would resurrect
/// a size the form only knows about because it loaded a stale product.
ProductSizeDiff computeSizeDiff(
  final List<ProductSize>? original,
  final List<SizeItem> target,
) {
  final originalById = {
    for (final size in original ?? const <ProductSize>[]) size.id: size,
  };

  final toAdd = <NewSizeItem>[];
  final toUpdate = <ProductSizeUpdate>[];
  final keptIds = <String>{};

  for (final item in target) {
    switch (item) {
      case NewSizeItem():
        toAdd.add(item);
      case ExistingSizeItem(:final id):
        final existing = originalById[id];
        if (existing == null) continue;
        keptIds.add(id);
        if (existing.name != item.name || existing.measurements != item.measurements) {
          toUpdate.add(ProductSizeUpdate(original: existing, target: item));
        }
    }
  }

  final idsToDelete = originalById.keys
      .where((final id) => !keptIds.contains(id))
      .toList();

  return ProductSizeDiff(toAdd: toAdd, toUpdate: toUpdate, idsToDelete: idsToDelete);
}
