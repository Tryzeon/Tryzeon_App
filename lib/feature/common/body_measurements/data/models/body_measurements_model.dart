import 'package:json_annotation/json_annotation.dart';

part 'body_measurements_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class BodyMeasurementsModel {
  const BodyMeasurementsModel({
    this.height,
    this.shoulder,
    this.chest,
    this.sleeve,
    this.waist,
    this.hips,
  });

  factory BodyMeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$BodyMeasurementsModelFromJson(json);

  final double? height;
  final double? shoulder;
  final double? chest;
  final double? sleeve;
  final double? waist;
  final double? hips;

  Map<String, dynamic> toJson() => _$BodyMeasurementsModelToJson(this);
}
