import 'package:tryzeon/feature/common/body_measurements/domain/entities/measurement_unit.dart';

export 'package:tryzeon/feature/common/body_measurements/domain/entities/measurement_unit.dart';

/// The dimensions of a *person* the shopper can record.
///
/// Most are body measurements in centimeters (chest/waist/hips are
/// circumferences measured on the body, not the flat measurements printed on a
/// garment's size chart); `weight` is in kilograms. Each member carries the
/// [unit] it is entered in and a `[min, max]` sanity range for validation. The
/// garment side has its own vocabulary in `GarmentMeasurementType`; the two are
/// deliberately separate types and are only related through the fit domain.
enum BodyMeasurementType {
  height('height', unit: MeasurementUnit.cm, min: 100, max: 250),
  weight('weight', unit: MeasurementUnit.kg, min: 20, max: 300),
  shoulder('shoulder', unit: MeasurementUnit.cm, min: 25, max: 70),
  chest('chest', unit: MeasurementUnit.cm, min: 50, max: 200),
  waist('waist', unit: MeasurementUnit.cm, min: 40, max: 200),
  hips('hips', unit: MeasurementUnit.cm, min: 50, max: 200),
  thigh('thigh', unit: MeasurementUnit.cm, min: 30, max: 120);

  const BodyMeasurementType(
    this.value, {
    required this.unit,
    required this.min,
    required this.max,
  });

  final String value;
  final MeasurementUnit unit;
  final double min;
  final double max;
}
