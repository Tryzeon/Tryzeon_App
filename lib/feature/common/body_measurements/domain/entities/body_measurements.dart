import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

export 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

part 'body_measurements.freezed.dart';

/// A shopper's own body dimensions. Lengths and circumferences are in
/// centimeters; [weight] is in kilograms.
@freezed
sealed class BodyMeasurements with _$BodyMeasurements {
  const factory BodyMeasurements({
    final double? height,
    final double? weight,
    final double? shoulder,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? thigh,
  }) = _BodyMeasurements;
  const BodyMeasurements._();

  factory BodyMeasurements.fromValues(final Map<BodyMeasurementType, double?> values) =>
      BodyMeasurements(
        height: values[BodyMeasurementType.height],
        weight: values[BodyMeasurementType.weight],
        shoulder: values[BodyMeasurementType.shoulder],
        chest: values[BodyMeasurementType.chest],
        waist: values[BodyMeasurementType.waist],
        hips: values[BodyMeasurementType.hips],
        thigh: values[BodyMeasurementType.thigh],
      );

  double? getValue(final BodyMeasurementType type) => switch (type) {
    BodyMeasurementType.height => height,
    BodyMeasurementType.weight => weight,
    BodyMeasurementType.shoulder => shoulder,
    BodyMeasurementType.chest => chest,
    BodyMeasurementType.waist => waist,
    BodyMeasurementType.hips => hips,
    BodyMeasurementType.thigh => thigh,
  };

  double? operator [](final BodyMeasurementType type) => getValue(type);

  int get filledCount =>
      BodyMeasurementType.values.where((final t) => getValue(t) != null).length;

  static int get fieldCount => BodyMeasurementType.values.length;
}
