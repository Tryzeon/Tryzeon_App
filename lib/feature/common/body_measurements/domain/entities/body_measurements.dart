import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

export 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

part 'body_measurements.freezed.dart';

/// A shopper's own body dimensions, in centimeters.
@freezed
sealed class BodyMeasurements with _$BodyMeasurements {
  const factory BodyMeasurements({
    final double? height,
    final double? shoulder,
    final double? chest,
    final double? sleeve,
    final double? waist,
    final double? hips,
  }) = _BodyMeasurements;
  const BodyMeasurements._();

  /// Builds an instance from a sparse map, ignoring unknown keys.
  factory BodyMeasurements.fromValues(final Map<BodyMeasurementType, double?> values) =>
      BodyMeasurements(
        height: values[BodyMeasurementType.height],
        shoulder: values[BodyMeasurementType.shoulder],
        chest: values[BodyMeasurementType.chest],
        sleeve: values[BodyMeasurementType.sleeve],
        waist: values[BodyMeasurementType.waist],
        hips: values[BodyMeasurementType.hips],
      );

  double? getValue(final BodyMeasurementType type) => switch (type) {
    BodyMeasurementType.height => height,
    BodyMeasurementType.shoulder => shoulder,
    BodyMeasurementType.chest => chest,
    BodyMeasurementType.sleeve => sleeve,
    BodyMeasurementType.waist => waist,
    BodyMeasurementType.hips => hips,
  };

  double? operator [](final BodyMeasurementType type) => getValue(type);

  /// How many of the [BodyMeasurementType] fields carry a value, for the
  /// "3 / 6 filled" progress indicators.
  int get filledCount =>
      BodyMeasurementType.values.where((final t) => getValue(t) != null).length;

  static int get fieldCount => BodyMeasurementType.values.length;
}
