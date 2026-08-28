import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_quantity.dart';

export 'package:tryzeon/feature/common/measurement/domain/entities/measurement_quantity.dart';

/// The dimensions of a *person* the shopper can record.
///
/// Most are body measurements in centimeters (chest/waist/hips are
/// circumferences measured on the body, not the flat measurements printed on a
/// garment's size chart); `weight` is a mass in kilograms. Each member carries
/// the physical [quantity] it expresses (which fixes its canonical unit) and a
/// `[min, max]` sanity range for validation. The garment side has its own
/// vocabulary in `GarmentMeasurementType`; the two are deliberately separate
/// types and are only related through the fit domain.
enum BodyMeasurementType {
  height('height', quantity: MeasurementQuantity.length, min: 100, max: 250),
  weight('weight', quantity: MeasurementQuantity.mass, min: 20, max: 300),
  shoulder('shoulder', quantity: MeasurementQuantity.length, min: 25, max: 70),
  chest('chest', quantity: MeasurementQuantity.length, min: 50, max: 200),
  waist('waist', quantity: MeasurementQuantity.length, min: 40, max: 200),
  hips('hips', quantity: MeasurementQuantity.length, min: 50, max: 200),
  thigh('thigh', quantity: MeasurementQuantity.length, min: 30, max: 120);

  const BodyMeasurementType(
    this.value, {
    required this.quantity,
    required this.min,
    required this.max,
  });

  final String value;
  final MeasurementQuantity quantity;
  final double min;
  final double max;
}
