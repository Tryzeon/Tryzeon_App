import 'package:equatable/equatable.dart';
import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.userId,
    required this.name,
    required this.measurements,
    this.avatarPath,
  });

  final String userId;
  final String name;
  final BodyMeasurements measurements;
  final String? avatarPath;

  @override
  List<Object?> get props => [userId, name, measurements, avatarPath];

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
}
