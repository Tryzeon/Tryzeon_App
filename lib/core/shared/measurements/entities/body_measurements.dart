import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

export 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

class BodyMeasurements extends Equatable {
  const BodyMeasurements({
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
  });

  factory BodyMeasurements.fromJson(final Map<String, dynamic> json) {
    return BodyMeasurements(
      height: (json['height'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      shoulder: (json['shoulder'] as num?)?.toDouble(),
      sleeve: (json['sleeve'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [height, chest, waist, hips, shoulder, sleeve];

  Map<String, dynamic> toJson() {
    return {for (final type in MeasurementType.values) type.name: this[type]};
  }

  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;

  // / 透過 Enum 動態取得數值
  double? operator [](final MeasurementType type) {
    switch (type) {
      case MeasurementType.height:
        return height;
      case MeasurementType.chest:
        return chest;
      case MeasurementType.waist:
        return waist;
      case MeasurementType.hips:
        return hips;
      case MeasurementType.shoulder:
        return shoulder;
      case MeasurementType.sleeve:
        return sleeve;
    }
  }

  BodyMeasurements copyWith({
    final double? height,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? shoulder,
    final double? sleeve,
  }) {
    return BodyMeasurements(
      height: height ?? this.height,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      shoulder: shoulder ?? this.shoulder,
      sleeve: sleeve ?? this.sleeve,
    );
  }
}
