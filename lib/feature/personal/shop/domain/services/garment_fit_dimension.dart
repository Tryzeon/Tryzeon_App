import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

/// The bridge between the garment vocabulary and the body vocabulary.
///
/// `GarmentMeasurementType` and `BodyMeasurementType` are independent types on
/// purpose, so *something* has to say which garment dimension speaks to which
/// body dimension. That knowledge belongs to the fit domain, not to either
/// measurement type: `common/product_size` must not know that shoppers have
/// bodies, and `common/body_measurements` must not know that garments exist.
///
/// A `null` counterpart means the dimension is display-only — a hem length
/// tells a shopper how long the garment is but says nothing about whether it
/// fits, exactly like body height says nothing about which size to pick.
extension GarmentFitDimension on GarmentMeasurementType {
  BodyMeasurementType? get comparableBodyType => switch (this) {
    GarmentMeasurementType.shoulderWidth => BodyMeasurementType.shoulder,
    GarmentMeasurementType.chestWidth => BodyMeasurementType.chest,
    GarmentMeasurementType.sleeveLength => BodyMeasurementType.sleeve,
    GarmentMeasurementType.waistWidth => BodyMeasurementType.waist,
    GarmentMeasurementType.hipWidth => BodyMeasurementType.hips,
    GarmentMeasurementType.garmentLength => null,
    GarmentMeasurementType.pantsLength => null,
    GarmentMeasurementType.skirtLength => null,
  };

  /// Whether the fit calculation may read this dimension at all.
  bool get affectsFit => comparableBodyType != null;
}

/// The garment dimensions the fit calculation is allowed to compare, in the
/// order they should be reported to the shopper.
final List<GarmentMeasurementType> fitComparableGarmentTypes = GarmentMeasurementType
    .values
    .where((final t) => t.affectsFit)
    .toList();
