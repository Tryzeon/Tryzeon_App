import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    required super.userId,
    required super.name,
    required super.measurements,
  });

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      measurements: BodyMeasurements.fromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'name': name, ...measurements.toJson()};
  }
}
