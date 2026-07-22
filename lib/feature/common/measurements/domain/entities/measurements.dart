import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_type.dart';

export 'package:tryzeon/feature/common/measurements/domain/entities/measurement_type.dart';

part 'measurements.freezed.dart';
part 'measurements.g.dart';

@freezed
sealed class Measurements with _$Measurements {
  const factory Measurements({
    final double? height,
    final double? shoulder,
    final double? chest,
    final double? sleeve,
    final double? waist,
    final double? hips,
  }) = _Measurements;
  const Measurements._();

  factory Measurements.fromJson(final Map<String, dynamic> json) =>
      _$MeasurementsFromJson(json);

  double? getValue(final MeasurementType type) => switch (type) {
    MeasurementType.height => height,
    MeasurementType.shoulder => shoulder,
    MeasurementType.chest => chest,
    MeasurementType.sleeve => sleeve,
    MeasurementType.waist => waist,
    MeasurementType.hips => hips,
  };

  /// 透過 Enum 動態取得數值
  double? operator [](final MeasurementType type) => getValue(type);
}
