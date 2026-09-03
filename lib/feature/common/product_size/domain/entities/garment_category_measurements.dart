import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

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
      GarmentMeasurementType.thighCircumference,
      GarmentMeasurementType.length,
    ],
    // A set spans top and bottom; "others" gives no signal. Both keep the
    // full chart available.
    WardrobeCategory.sets || WardrobeCategory.others => GarmentMeasurementType.values,
  };
}

List<GarmentMeasurementType> relevantMeasurementTypesFor(
  final WardrobeCategory? category,
) => category?.relevantMeasurementTypes ?? GarmentMeasurementType.values;
