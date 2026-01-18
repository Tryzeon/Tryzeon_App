import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.userId,
    required super.name,
    required super.measurements,
    super.avatarPath,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfileModel.fromJson(final Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      measurements: BodyMeasurements.fromJson(json),
      avatarPath: json['avatar_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'avatar_path': avatarPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      ...measurements.toJson(),
    };
  }
}
