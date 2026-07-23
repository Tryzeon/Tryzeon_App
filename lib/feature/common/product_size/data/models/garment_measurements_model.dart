import 'package:json_annotation/json_annotation.dart';

part 'garment_measurements_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class GarmentMeasurementsModel {
  const GarmentMeasurementsModel({
    this.shoulderWidth,
    this.chestWidth,
    this.sleeveLength,
    this.waistWidth,
    this.hipWidth,
    this.garmentLength,
    this.pantsLength,
    this.skirtLength,
  });

  factory GarmentMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$GarmentMeasurementsModelFromJson(json);

  final double? shoulderWidth;
  final double? chestWidth;
  final double? sleeveLength;
  final double? waistWidth;
  final double? hipWidth;
  final double? garmentLength;
  final double? pantsLength;
  final double? skirtLength;

  Map<String, dynamic> toJson() => _$GarmentMeasurementsModelToJson(this);
}
