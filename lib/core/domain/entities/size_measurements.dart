import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/domain/entities/measurement_type.dart';

class SizeMeasurements extends Equatable {
  const SizeMeasurements({
    this.height,
    this.weight,
    this.chest,
    this.waist,
    this.hips,
    this.shoulderWidth,
    this.sleeveLength,
    this.heightOffset,
    this.weightOffset,
    this.chestOffset,
    this.waistOffset,
    this.hipsOffset,
    this.shoulderWidthOffset,
    this.sleeveLengthOffset,
  });

  factory SizeMeasurements.fromJson(final Map<String, dynamic> json) {
    return SizeMeasurements(
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      chest: (json['chest'] as num?)?.toDouble(),
      waist: (json['waist'] as num?)?.toDouble(),
      hips: (json['hips'] as num?)?.toDouble(),
      shoulderWidth: (json['shoulder_width'] as num?)?.toDouble(),
      sleeveLength: (json['sleeve_length'] as num?)?.toDouble(),
      heightOffset: (json['height_offset'] as num?)?.toDouble(),
      weightOffset: (json['weight_offset'] as num?)?.toDouble(),
      chestOffset: (json['chest_offset'] as num?)?.toDouble(),
      waistOffset: (json['waist_offset'] as num?)?.toDouble(),
      hipsOffset: (json['hips_offset'] as num?)?.toDouble(),
      shoulderWidthOffset: (json['shoulder_width_offset'] as num?)?.toDouble(),
      sleeveLengthOffset: (json['sleeve_length_offset'] as num?)?.toDouble(),
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
    heightOffset,
    weightOffset,
    chestOffset,
    waistOffset,
    hipsOffset,
    shoulderWidthOffset,
    sleeveLengthOffset,
  ];

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    for (final type in MeasurementType.values) {
      final value = getValue(type);
      if (value != null) {
        data[type.key] = value;
      }
      final offset = getOffset(type);
      if (offset != null) {
        data['${type.key}_offset'] = offset;
      }
    }
    return data;
  }

  final double? height;
  final double? weight;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulderWidth;
  final double? sleeveLength;

  final double? heightOffset;
  final double? weightOffset;
  final double? chestOffset;
  final double? waistOffset;
  final double? hipsOffset;
  final double? shoulderWidthOffset;
  final double? sleeveLengthOffset;

  double? getValue(final MeasurementType type) {
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

  double? getOffset(final MeasurementType type) {
    switch (type) {
      case MeasurementType.height:
        return heightOffset;
      case MeasurementType.weight:
        return weightOffset;
      case MeasurementType.chest:
        return chestOffset;
      case MeasurementType.waist:
        return waistOffset;
      case MeasurementType.hips:
        return hipsOffset;
      case MeasurementType.shoulderWidth:
        return shoulderWidthOffset;
      case MeasurementType.sleeveLength:
        return sleeveLengthOffset;
    }
  }

  /// 取得該測量類型的區間範圍 (min, max)
  /// 如果沒有值，回傳 null
  /// 如果沒有 offset，預設為 0
  (double min, double max)? getRange(final MeasurementType type) {
    final value = getValue(type);
    if (value == null) return null;

    final offset = getOffset(type) ?? 0.0;
    return (value - offset, value + offset);
  }

  SizeMeasurements copyWith({
    final double? height,
    final double? weight,
    final double? chest,
    final double? waist,
    final double? hips,
    final double? shoulderWidth,
    final double? sleeveLength,
    final double? heightOffset,
    final double? weightOffset,
    final double? chestOffset,
    final double? waistOffset,
    final double? hipsOffset,
    final double? shoulderWidthOffset,
    final double? sleeveLengthOffset,
  }) {
    return SizeMeasurements(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      shoulderWidth: shoulderWidth ?? this.shoulderWidth,
      sleeveLength: sleeveLength ?? this.sleeveLength,
      heightOffset: heightOffset ?? this.heightOffset,
      weightOffset: weightOffset ?? this.weightOffset,
      chestOffset: chestOffset ?? this.chestOffset,
      waistOffset: waistOffset ?? this.waistOffset,
      hipsOffset: hipsOffset ?? this.hipsOffset,
      shoulderWidthOffset: shoulderWidthOffset ?? this.shoulderWidthOffset,
      sleeveLengthOffset: sleeveLengthOffset ?? this.sleeveLengthOffset,
    );
  }
}
