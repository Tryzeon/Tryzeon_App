import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurements.dart';

part 'size_item.freezed.dart';

/// Unified representation of product sizes in the editing flow: the full list
/// the store owner wants to end up with. The data layer diffs it against the
/// product's current sizes to work out what to insert, update and delete.
@freezed
sealed class SizeItem with _$SizeItem {
  /// A size that already exists in the database.
  const factory SizeItem.existing({
    required final String id,
    required final String name,
    final GarmentMeasurements? measurements,
  }) = ExistingSizeItem;

  /// A size the store owner just added in the form, not yet persisted.
  const factory SizeItem.newSize({
    required final String name,
    final GarmentMeasurements? measurements,
  }) = NewSizeItem;
}
