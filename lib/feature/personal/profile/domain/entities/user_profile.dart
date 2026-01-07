import 'package:tryzeon/shared/models/body_measurements.dart';

class UserProfile {
  UserProfile({required this.userId, required this.name, required this.measurements});

  final String userId;
  final String name;
  final BodyMeasurements measurements;

  UserProfile copyWith({
    final String? userId,
    final String? name,
    final BodyMeasurements? measurements,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
    );
  }

  Map<String, dynamic> getDirtyFields(final UserProfile target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    updates.addAll(measurements.getDirtyFields(target.measurements));

    return updates;
  }
}
