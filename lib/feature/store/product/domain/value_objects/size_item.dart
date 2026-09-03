import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurements.dart';

part 'size_item.freezed.dart';

@freezed
sealed class SizeItem with _$SizeItem {
  const factory SizeItem.existing({
    required final String id,
    required final String name,
    final GarmentMeasurements? measurements,
  }) = ExistingSizeItem;

  const factory SizeItem.newSize({
    required final String name,
    final GarmentMeasurements? measurements,
  }) = NewSizeItem;
}
