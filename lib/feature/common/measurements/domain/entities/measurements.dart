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
    final double? heightOffset,
    final double? shoulderOffset,
    final double? chestOffset,
    final double? sleeveOffset,
    final double? waistOffset,
    final double? hipsOffset,
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

  double? getOffset(final MeasurementType type) => switch (type) {
    MeasurementType.height => heightOffset,
    MeasurementType.shoulder => shoulderOffset,
    MeasurementType.chest => chestOffset,
    MeasurementType.sleeve => sleeveOffset,
    MeasurementType.waist => waistOffset,
    MeasurementType.hips => hipsOffset,
  };

  /// 透過 Enum 動態取得數值
  double? operator [](final MeasurementType type) => getValue(type);

  /// 取得該測量類型的區間範圍 (min, max)
  /// 如果沒有值，回傳 null
  /// 如果沒有 offset，預設為 0
  (double min, double max)? getRange(final MeasurementType type) {
    final value = getValue(type);
    if (value == null) return null;

    final offset = getOffset(type) ?? 0.0;
    return (value - offset, value + offset);
  }
}
