import '../../domain/entities/garment_measurement_type.dart';

export '../../domain/entities/garment_measurement_type.dart';

/// UI display extensions for [GarmentMeasurementType] in the presentation layer.
extension GarmentMeasurementTypeUiMapper on GarmentMeasurementType {
  /// The localized label for UI rendering.
  String get label => switch (this) {
    GarmentMeasurementType.shoulderWidth => '肩寬',
    GarmentMeasurementType.chestWidth => '胸寬',
    GarmentMeasurementType.sleeveLength => '袖長',
    GarmentMeasurementType.waistWidth => '腰寬',
    GarmentMeasurementType.hipWidth => '臀寬',
    GarmentMeasurementType.length => '長度',
  };
}
