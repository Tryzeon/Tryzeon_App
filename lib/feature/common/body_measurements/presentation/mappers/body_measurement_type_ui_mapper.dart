import '../../domain/entities/body_measurement_type.dart';

export '../../domain/entities/body_measurement_type.dart';

extension BodyMeasurementTypeUiMapper on BodyMeasurementType {
  String get label => switch (this) {
    BodyMeasurementType.height => '身高',
    BodyMeasurementType.weight => '體重',
    BodyMeasurementType.shoulder => '肩寬',
    BodyMeasurementType.chest => '胸圍',
    BodyMeasurementType.waist => '腰圍',
    BodyMeasurementType.hips => '臀圍',
    BodyMeasurementType.thigh => '大腿圍',
  };
}
