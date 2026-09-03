import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

/// A `null` counterpart means the dimension is display-only — the garment's
/// length tells a shopper how long it is but says nothing about whether it
/// fits, exactly like body height says nothing about which size to pick.
extension GarmentFitDimension on GarmentMeasurementType {
  BodyMeasurementType? get comparableBodyType => switch (this) {
    GarmentMeasurementType.shoulderWidth => BodyMeasurementType.shoulder,
    GarmentMeasurementType.chestCircumference => BodyMeasurementType.chest,
    GarmentMeasurementType.waistCircumference => BodyMeasurementType.waist,
    GarmentMeasurementType.hipCircumference => BodyMeasurementType.hips,
    GarmentMeasurementType.thighCircumference => BodyMeasurementType.thigh,
    GarmentMeasurementType.sleeveLength => null,
    GarmentMeasurementType.length => null,
  };

  bool get affectsFit => comparableBodyType != null;
}

/// In the order the dimensions should be reported to the shopper.
final List<GarmentMeasurementType> fitComparableGarmentTypes = GarmentMeasurementType
    .values
    .where((final t) => t.affectsFit)
    .toList();
