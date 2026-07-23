import 'package:json_annotation/json_annotation.dart';

part 'garment_measurements_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GarmentMeasurementsModel {
  const GarmentMeasurementsModel({
    this.shoulderWidth,
    this.chestCircumference,
    this.sleeveLength,
    this.waistCircumference,
    this.hipCircumference,
    this.length,
  });

  factory GarmentMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$GarmentMeasurementsModelFromJson(json);

  final double? shoulderWidth;
  final double? chestCircumference;
  final double? sleeveLength;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? length;

  Map<String, dynamic> toJson() => _$GarmentMeasurementsModelToJson(this);
}
