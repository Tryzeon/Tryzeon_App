import 'package:flutter/material.dart';

/// 身型測量欄位定義
enum MeasurementType {
  height('身高 (cm)', 'height', Icons.height_rounded),
  weight('體重 (kg)', 'weight', Icons.monitor_weight_outlined),
  chest('胸圍 (cm)', 'chest', Icons.accessibility_rounded),
  waist('腰圍 (cm)', 'waist', Icons.accessibility_rounded),
  hips('臀圍 (cm)', 'hips', Icons.accessibility_rounded),
  shoulderWidth('肩寬 (cm)', 'shoulder_width', Icons.accessibility_rounded),
  sleeveLength('袖長 (cm)', 'sleeve_length', Icons.accessibility_rounded);

  const MeasurementType(this.label, this.key, this.icon);
  final String label;
  final IconData icon;
  final String key;
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

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    for (final type in MeasurementType.values) {
      final value = this[type];
      if (value != null) {
        data[type.key] = value;
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

  /// 比對另一個 BodyMeasurements，回傳差異的 Map
  Map<String, dynamic> getDirtyFields(final BodyMeasurements target) {
    final updates = <String, dynamic>{};
    for (final type in MeasurementType.values) {
      final oldValue = this[type];
      final newValue = target[type];

      if (oldValue != newValue) {
        updates[type.key] = newValue;
      }
    }
    return updates;
  }
}
