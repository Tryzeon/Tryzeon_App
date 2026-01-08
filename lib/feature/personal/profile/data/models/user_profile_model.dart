import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    required super.userId,
    required super.name,
    required super.measurements,
    super.avatarPath,
  });

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      measurements: BodyMeasurements.fromJson(json),
      avatarPath: json['avatar_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar_path': avatarPath,
      ...measurements.toJson(),
    };
  }
}
