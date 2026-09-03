import '../../domain/entities/garment_measurement_type.dart';

export '../../domain/entities/garment_measurement_type.dart';

extension GarmentMeasurementTypeUiMapper on GarmentMeasurementType {
  String get label => switch (this) {
    GarmentMeasurementType.shoulderWidth => '肩寬',
    GarmentMeasurementType.chestCircumference => '胸圍',
    GarmentMeasurementType.sleeveLength => '袖長',
    GarmentMeasurementType.waistCircumference => '腰圍',
    GarmentMeasurementType.hipCircumference => '臀圍',
    GarmentMeasurementType.thighCircumference => '大腿圍',
    GarmentMeasurementType.length => '長度',
  };
}
