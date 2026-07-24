import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

/// The bridge between the garment-type vocabulary and the size-chart
/// vocabulary: which dimensions are meaningful to measure for each
/// [WardrobeCategory].
///
/// This is garment-domain knowledge (a skirt has no sleeve length, a top has
/// no hip circumference), so it lives next to [GarmentMeasurementType] rather
/// than in either the store or shop feature — both sides consult it.
extension GarmentCategoryMeasurements on WardrobeCategory {
  List<GarmentMeasurementType> get relevantMeasurementTypes => switch (this) {
    WardrobeCategory.top || WardrobeCategory.outerwear => const [
      GarmentMeasurementType.shoulderWidth,
      GarmentMeasurementType.chestCircumference,
      GarmentMeasurementType.sleeveLength,
      GarmentMeasurementType.length,
    ],
    WardrobeCategory.bottoms => const [
      GarmentMeasurementType.waistCircumference,
      GarmentMeasurementType.hipCircumference,
      GarmentMeasurementType.length,
    ],
    // A set spans top and bottom; "others" gives no signal. Both keep the
    // full chart available.
    WardrobeCategory.sets || WardrobeCategory.others => GarmentMeasurementType.values,
  };
}

/// The relevant dimensions for [category], falling back to every dimension
/// when the selection gives no signal: nothing selected yet, the category
/// list not loaded, or a category without a wardrobe classification — an
/// unknown garment type must not hide fields the store owner may need.
List<GarmentMeasurementType> relevantMeasurementTypesFor(
  final WardrobeCategory? category,
) => category?.relevantMeasurementTypes ?? GarmentMeasurementType.values;
