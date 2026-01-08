import 'package:tryzeon/core/domain/entities/body_measurements.dart';

class UserProfile {
  UserProfile({
    required this.userId,
    required this.name,
    required this.measurements,
    this.avatarPath,
  });

  final String userId;
  final String name;
  final BodyMeasurements measurements;
  final String? avatarPath;

  UserProfile copyWith({
    final String? userId,
    final String? name,
    final BodyMeasurements? measurements,
    final String? avatarPath,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> getDirtyFields(final UserProfile target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    if (avatarPath != target.avatarPath) {
      updates['avatar_path'] = target.avatarPath;
    }

    updates.addAll(measurements.getDirtyFields(target.measurements));

    return updates;
  }
}
