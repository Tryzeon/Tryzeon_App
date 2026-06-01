import 'dart:io';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class UserProfileRepository {
  Future<Result<UserProfile, Failure>> getUserProfile({final bool forceRefresh = false});

  Future<Result<File, Failure>> getUserAvatar(final String path);

  Future<Result<void, Failure>> updateUserProfile({
    required final String name,
    final Gender? gender,
    final int? age,
  });

  Future<Result<void, Failure>> updateStylePreferences({
    required final List<ClothingStyle> stylePreferences,
  });

  Future<Result<void, Failure>> updateUserBodyMeasurements({
    required final Measurements measurements,
  });

  Future<Result<void, Failure>> updateUserAvatar({
    required final File avatarFile,
    final String? previousAvatarPath,
  });

  Future<Result<void, Failure>> completeUserOnboarding({
    final Gender? gender,
    final int? age,
    final List<ClothingStyle>? stylePreferences,
  });
}
