import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

import 'package:tryzeon/core/shared/measurements/mappers/measurement_type_data_mapper.dart';

export 'package:tryzeon/core/shared/measurements/entities/measurement_type.dart';

class BodyMeasurements extends Equatable {
  const BodyMeasurements({
    this.height,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.shoulderWidth,
    this.sleeveLength,
  });

  factory BodyMeasurements.fromJson(final Map<String, dynamic> json) {
    return BodyMeasurements(
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      shoulderWidth: (json['shoulder_width'] as num?)?.toDouble(),
      sleeveLength: (json['sleeve_length'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    height,
    weight,
    chest,
    waist,
    hips,
    shoulderWidth,
    sleeveLength,
  ];

  Map<String, dynamic> toJson() {
    return {for (final type in MeasurementType.values) type.key: this[type]};
  }

  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulderWidth;
  final double? sleeveLength;

  // / 透過 Enum 動態取得數值
  double? operator [](final MeasurementType type) {
    switch (type) {
      case MeasurementType.height:
        return height;
      case MeasurementType.weight:
        return weight;
      case MeasurementType.chest:
        return chest;
      case MeasurementType.waist:
        return waist;
      case MeasurementType.hips:
        return hips;
      case MeasurementType.shoulderWidth:
        return shoulderWidth;
      case MeasurementType.sleeveLength:
        return sleeveLength;
    }
  }

  BodyMeasurements copyWith({
    final double? height,
    final double? weight,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? shoulderWidth,
    final double? sleeveLength,
  }) {
    return BodyMeasurements(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      sleeveLength: sleeveLength ?? this.sleeveLength,
    );
  }
}
