import '../entities/measurement_type.dart';

extension MeasurementTypeDataMapper on MeasurementType {
  String get key {
    switch (this) {
      case MeasurementType.height:
        return 'height';
      case MeasurementType.weight:
        return 'weight';
      case MeasurementType.chest:
        return 'chest';
      case MeasurementType.waist:
        return 'waist';
      case MeasurementType.hips:
        return 'hips';
      case MeasurementType.shoulderWidth:
        return 'shoulder_width';
      case MeasurementType.sleeveLength:
        return 'sleeve_length';
    }
  }
}
