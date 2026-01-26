import 'package:flutter/material.dart';
import '../../entities/measurement_type.dart';

export '../../entities/measurement_type.dart';

extension MeasurementTypeUiMapper on MeasurementType {
  String get label {
    switch (this) {
      case MeasurementType.height:
        return '身高 (cm)';
      case MeasurementType.chest:
        return '胸圍 (cm)';
      case MeasurementType.waist:
        return '腰圍 (cm)';
      case MeasurementType.hips:
        return '臀圍 (cm)';
      case MeasurementType.shoulderWidth:
        return '肩寬 (cm)';
      case MeasurementType.sleeveLength:
        return '袖長 (cm)';
    }
  }

  IconData get icon {
    switch (this) {
      case MeasurementType.height:
        return Icons.height_rounded;
      case MeasurementType.chest:
        return Icons.accessibility_rounded;
      case MeasurementType.waist:
        return Icons.accessibility_rounded;
      case MeasurementType.hips:
        return Icons.accessibility_rounded;
      case MeasurementType.shoulderWidth:
        return Icons.accessibility_rounded;
      case MeasurementType.sleeveLength:
        return Icons.accessibility_rounded;
    }
  }
}
