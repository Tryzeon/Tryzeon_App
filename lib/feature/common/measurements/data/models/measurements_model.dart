import 'package:json_annotation/json_annotation.dart';

part 'measurements_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class MeasurementsModel {
  const MeasurementsModel({
    this.height,
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.sleeve,
  });

  factory MeasurementsModel.fromJson(final Map<String, dynamic> json) =>
      _$MeasurementsModelFromJson(json);

  final double? height;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? sleeve;

  Map<String, dynamic> toJson() => _$MeasurementsModelToJson(this);
}
