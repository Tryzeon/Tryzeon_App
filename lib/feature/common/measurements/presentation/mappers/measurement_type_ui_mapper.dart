import 'package:flutter/material.dart';
import '../../domain/entities/measurement_type.dart';

export '../../domain/entities/measurement_type.dart';

/// UI display extensions for [MeasurementType] in Presentation Layer.
extension MeasurementTypeUiMapper on MeasurementType {
  /// The localized label for UI rendering.
  String get label => switch (this) {
    MeasurementType.height => '身高',
    MeasurementType.chest => '胸圍',
    MeasurementType.waist => '腰圍',
    MeasurementType.hips => '臀圍',
    MeasurementType.shoulder => '肩寬',
    MeasurementType.sleeve => '袖長',
  };

  /// The icon representing this measurement type.
  IconData get icon => switch (this) {
    MeasurementType.height => Icons.height_rounded,
    MeasurementType.chest => Icons.accessibility_rounded,
    MeasurementType.waist => Icons.accessibility_rounded,
    MeasurementType.hips => Icons.accessibility_rounded,
    MeasurementType.shoulder => Icons.accessibility_rounded,
    MeasurementType.sleeve => Icons.accessibility_rounded,
  };
}
