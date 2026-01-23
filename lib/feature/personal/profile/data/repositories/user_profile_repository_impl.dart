import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';
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

  @override
  Future<Result<UserProfile, String>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      // Cache-first (skip if forceRefresh)
      if (!forceRefresh) {
        final cached = await _localDataSource.getCache();
        if (cached != null) return Ok(cached);
      }

      // Fetch from API
      final profile = await _remoteDataSource.fetchUserProfile();

      // Update cache
      await _localDataSource.setCache(profile);

      return Ok(profile);
    } catch (e) {
      AppLogger.error('無法載入個人資料', e);
      return const Err('無法載入個人資料，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> updateUserProfile({
    required final UserProfile original,
    required final UserProfile target,
    final File? avatarFile,
  }) async {
    try {
      UserProfile finalTarget = target;

      // Handle Avatar Upload
      if (avatarFile != null) {
        final newAvatarPath = await _remoteDataSource.uploadAvatar(avatarFile);
        finalTarget = target.copyWith(avatarPath: newAvatarPath);

        // Optimistic cache update for image
        final bytes = await avatarFile.readAsBytes();
        await _localDataSource.saveAvatar(bytes, newAvatarPath);
      }

      final hasChanges = original != finalTarget;

      if (!hasChanges) {
        return const Ok(null);
      }

      final targetModel = UserProfileModel.fromEntity(finalTarget);

      final updatedProfile = await _remoteDataSource.updateUserProfile(targetModel);

      await _localDataSource.setCache(updatedProfile);

      // Clean up old avatar if changed
      if (avatarFile != null &&
          original.avatarPath != null &&
          original.avatarPath!.isNotEmpty) {
        // Fire and forget
        _remoteDataSource.deleteAvatar(original.avatarPath!);
        _localDataSource.deleteAvatar(original.avatarPath!);
      }

      return const Ok(null);
    } catch (e) {
      AppLogger.error('個人資料更新失敗', e);

      return const Err('個人資料更新失敗，請稍後再試');
    }
  }

  @override
  Future<Result<File, String>> getUserAvatar(final String path) async {
    try {
      // 1. Try Local Cache
      final cachedAvatar = await _localDataSource.getCachedAvatar(path);
      if (cachedAvatar != null) {
        return Ok(cachedAvatar);
      }

      // 2. If missing, generate URL and download
      final url = await _remoteDataSource.createSignedUrl(path);
      final downloadedAvatar = await _localDataSource.downloadAvatar(path, url);

      if (downloadedAvatar == null) {
        return const Err('無法獲取個人頭像，請稍後再試');
      }

      return Ok(downloadedAvatar);
    } catch (e) {
      AppLogger.error('無法載入個人頭像', e);
      return const Err('無法載入個人頭像，請稍後再試');
    }
  }
}
