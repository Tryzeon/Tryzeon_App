import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

export 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

part 'garment_measurements.freezed.dart';

/// One size's flat measurements, in centimeters.
///
/// Every field is optional: a size chart is inherently sparse — a skirt has no
/// sleeve length, a top has no hip width, and store owners publish only the
/// dimensions they actually measured.
@freezed
sealed class GarmentMeasurements with _$GarmentMeasurements {
  const factory GarmentMeasurements({
    final double? shoulderWidth,
    final double? chestWidth,
    final double? sleeveLength,
    final double? waistWidth,
    final double? hipWidth,
    final double? length,
  }) = _GarmentMeasurements;
  const GarmentMeasurements._();

  /// Builds an instance from a sparse map, ignoring unknown keys.
  factory GarmentMeasurements.fromValues(
    final Map<GarmentMeasurementType, double?> values,
  ) => GarmentMeasurements(
    shoulderWidth: values[GarmentMeasurementType.shoulderWidth],
    chestWidth: values[GarmentMeasurementType.chestWidth],
    sleeveLength: values[GarmentMeasurementType.sleeveLength],
    waistWidth: values[GarmentMeasurementType.waistWidth],
    hipWidth: values[GarmentMeasurementType.hipWidth],
    length: values[GarmentMeasurementType.length],
  );

  double? getValue(final GarmentMeasurementType type) => switch (type) {
    GarmentMeasurementType.shoulderWidth => shoulderWidth,
    GarmentMeasurementType.chestWidth => chestWidth,
    GarmentMeasurementType.sleeveLength => sleeveLength,
    GarmentMeasurementType.waistWidth => waistWidth,
    GarmentMeasurementType.hipWidth => hipWidth,
    GarmentMeasurementType.length => length,
  };

  double? operator [](final GarmentMeasurementType type) => getValue(type);

  /// The dimensions this size actually carries a value for. Drives the size
  /// chart's columns so empty dimensions never render as a column of dashes.
  Iterable<GarmentMeasurementType> get filledTypes =>
      GarmentMeasurementType.values.where((final t) => getValue(t) != null);
}
