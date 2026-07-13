import 'dart:io';

import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/measurements/data/mappers/measurements_mappr.dart';
import 'package:tryzeon/feature/common/measurements/data/models/measurements_model.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({
    required final UserProfileRemoteDataSource remoteDataSource,
    required final UserProfileLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final UserProfileRemoteDataSource _remoteDataSource;
  final UserProfileLocalDataSource _localDataSource;
  static const _mappr = PersonalMappr();
  static const _measurementsMappr = MeasurementsMappr();

  @override
  Future<Result<UserProfile, Failure>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Try Local Cache
      if (!forceRefresh) {
        try {
          final cachedProfile = await _localDataSource.getUserProfile();
          switch (cachedProfile) {
            case CacheHit<UserProfileModel>(:final data):
              final profile = _mappr.convert<UserProfileModel, UserProfile>(data);
              return Ok(profile);
            case CacheEmpty<UserProfileModel>():
            case CacheMiss<UserProfileModel>():
              break;
          }
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Local cache read failed, falling back to remote',
            e,
            stackTrace,
          );
        }
      }

      // 2. Fetch from API
      final remoteProfile = await _remoteDataSource.getUserProfile();

      // 3. Update Cache
      try {
        await _localDataSource.saveUserProfile(remoteProfile);
      } catch (e, stackTrace) {
        AppLogger.warning('Failed to save user profile to cache', e, stackTrace);
      }

      final profile = _mappr.convert<UserProfileModel, UserProfile>(remoteProfile);
      return Ok(profile);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateUserProfile({
    required final String name,
    final Gender? gender,
    final AgeRange? ageRange,
  }) async {
    try {
      final updatedProfile = await _remoteDataSource.updateUserProfile(
        name: name,
        gender: gender?.value,
        ageRange: ageRange?.value,
      );
      await _localDataSource.saveUserProfile(updatedProfile);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user profile', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateStylePreferences({
    required final List<ClothingStyle> stylePreferences,
  }) async {
    try {
      final updatedProfile = await _remoteDataSource.updateStylePreferences(
        stylePreferences.map((final style) => style.value).toList(),
      );
      await _localDataSource.saveUserProfile(updatedProfile);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update style preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateUserBodyMeasurements({
    required final Measurements measurements,
  }) async {
    try {
      final measurementsModel = _measurementsMappr
          .convert<Measurements, MeasurementsModel>(measurements);
      final updatedProfile = await _remoteDataSource.updateUserBodyMeasurements(
        measurementsModel,
      );

      await _localDataSource.saveUserProfile(updatedProfile);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user body measurements', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> completeUserOnboarding({
    final Gender? gender,
    final AgeRange? ageRange,
    final List<ClothingStyle>? stylePreferences,
  }) async {
    try {
      final updatedProfile = await _remoteDataSource.completeUserOnboarding(
        gender: gender?.value,
        ageRange: ageRange?.value,
        stylePreferences: stylePreferences?.map((final style) => style.value).toList(),
      );

      await _localDataSource.saveUserProfile(updatedProfile);

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete user onboarding', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> updateUserAvatar({
    required final File avatarFile,
    final String? previousAvatarPath,
  }) async {
    try {
      final newAvatarPath = await _remoteDataSource.uploadAvatar(avatarFile);

      final bytes = await avatarFile.readAsBytes();
      await _localDataSource.saveAvatar(bytes, newAvatarPath);

      final updatedProfile = await _remoteDataSource.updateUserAvatarPath(newAvatarPath);

      await _localDataSource.saveUserProfile(updatedProfile);

      if (previousAvatarPath != null && previousAvatarPath.isNotEmpty) {
        try {
          await _remoteDataSource.deleteAvatar(previousAvatarPath);
          await _localDataSource.deleteAvatar(previousAvatarPath);
        } catch (e, stackTrace) {
          AppLogger.warning('Failed to delete previous avatar', e, stackTrace);
        }
      }

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update user avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<File, Failure>> getUserAvatar(final String path) async {
    try {
      // 1. Try Local Cache
      final cachedAvatar = await _localDataSource.getAvatar(path);
      if (cachedAvatar != null) {
        return Ok(cachedAvatar);
      }

      // 2. If missing, generate URL and download
      final url = await _remoteDataSource.createSignedUrl(path);
      final downloadedAvatar = await _localDataSource.downloadAvatar(path, url);

      if (downloadedAvatar == null) {
        return const Err(UnknownFailure('無法獲取個人頭像'));
      }

      return Ok(downloadedAvatar);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load profile avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
