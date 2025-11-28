import 'package:flutter/material.dart';

/// 身型測量欄位定義
enum MeasurementType {
  height('身高 (cm)', Icons.height_rounded),
  weight('體重 (kg)', Icons.monitor_weight_outlined),
  chest('胸圍 (cm)', Icons.accessibility_rounded),
  waist('腰圍 (cm)', Icons.accessibility_rounded),
  hips('臀圍 (cm)', Icons.accessibility_rounded),
  shoulderWidth('肩寬 (cm)', Icons.accessibility_rounded),
  sleeveLength('袖長 (cm)', Icons.accessibility_rounded);

  const MeasurementType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class BodyMeasurements {
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
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      shoulderWidth: json['shoulder_width']?.toDouble(),
      sleeveLength: json['sleeve_length']?.toDouble(),
    );
  }

  factory BodyMeasurements.fromTypeMap(
    final Map<MeasurementType, double?> map,
  ) {
    return BodyMeasurements(
      height: map[MeasurementType.height],
      weight: map[MeasurementType.weight],
      chest: map[MeasurementType.chest],
      waist: map[MeasurementType.waist],
      hips: map[MeasurementType.hips],
      shoulderWidth: map[MeasurementType.shoulderWidth],
      sleeveLength: map[MeasurementType.sleeveLength],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (hips != null) 'hips': hips,
      if (shoulderWidth != null) 'shoulder_width': shoulderWidth,
      if (sleeveLength != null) 'sleeve_length': sleeveLength,
    };
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

  @override
  String toString() {
    return 'height: $height, weight: $weight, chest: $chest, waist: $waist, hips: $hips, shoulderWidth: $shoulderWidth, sleeveLength: $sleeveLength)';
  }
}
