import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

part 'garment_measurements.freezed.dart';

/// One size's garment measurements, in centimeters.
///
/// Every field is optional: a size chart is inherently sparse — a skirt has no
/// sleeve length, a top has no hip circumference, and store owners publish
/// only the dimensions they actually measured.
@freezed
sealed class GarmentMeasurements with _$GarmentMeasurements {
  const factory GarmentMeasurements({
    final double? shoulderWidth,
    final double? chestCircumference,
    final double? sleeveLength,
    final double? waistCircumference,
    final double? hipCircumference,
    final double? thighCircumference,
    final double? length,
  }) = _GarmentMeasurements;
  const GarmentMeasurements._();

  /// Builds an instance from a sparse map, ignoring unknown keys.
  factory GarmentMeasurements.fromValues(
    final Map<GarmentMeasurementType, double?> values,
  ) => GarmentMeasurements(
    shoulderWidth: values[GarmentMeasurementType.shoulderWidth],
    chestCircumference: values[GarmentMeasurementType.chestCircumference],
    sleeveLength: values[GarmentMeasurementType.sleeveLength],
    waistCircumference: values[GarmentMeasurementType.waistCircumference],
    hipCircumference: values[GarmentMeasurementType.hipCircumference],
    thighCircumference: values[GarmentMeasurementType.thighCircumference],
    length: values[GarmentMeasurementType.length],
  );

  double? getValue(final GarmentMeasurementType type) => switch (type) {
    GarmentMeasurementType.shoulderWidth => shoulderWidth,
    GarmentMeasurementType.chestCircumference => chestCircumference,
    GarmentMeasurementType.sleeveLength => sleeveLength,
    GarmentMeasurementType.waistCircumference => waistCircumference,
    GarmentMeasurementType.hipCircumference => hipCircumference,
    GarmentMeasurementType.thighCircumference => thighCircumference,
    GarmentMeasurementType.length => length,
  };

  double? operator [](final GarmentMeasurementType type) => getValue(type);
}
