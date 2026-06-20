import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';

part 'user_profile.freezed.dart';

@freezed
sealed class UserProfile with _$UserProfile {
  const factory UserProfile({
    required final String userId,
    required final String name,
    required final DateTime createdAt,
    required final DateTime updatedAt,
    final Measurements? measurements,
    final String? avatarPath,
    final String? email,
    final Gender? gender,
    final AgeRange? ageRange,
    final List<ClothingStyle>? stylePreferences,
    @Default(false) final bool isOnboarded,
  }) = _UserProfile;
}
