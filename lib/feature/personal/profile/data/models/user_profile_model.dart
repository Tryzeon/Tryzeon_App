import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/data/models/body_measurements_model.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfileModel {
  const UserProfileModel({
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.measurements,
    this.avatarPath,
    this.gender,
    this.ageRange,
    this.stylePreferences,
    this.isOnboarded = false,
  });

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? email;
  final BodyMeasurementsModel? measurements;
  final String? avatarPath;
  final String? gender;
  final String? ageRange;
  final List<String>? stylePreferences;
  @JsonKey(defaultValue: false)
  final bool isOnboarded;

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);
}
