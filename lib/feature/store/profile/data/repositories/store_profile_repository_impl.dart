import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_local_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/datasources/store_profile_remote_datasource.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class StoreProfileRepositoryImpl implements StoreProfileRepository {
  StoreProfileRepositoryImpl({
    required final StoreProfileRemoteDataSource remoteDataSource,
    required final StoreProfileLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final StoreProfileRemoteDataSource _remoteDataSource;
  final StoreProfileLocalDataSource _localDataSource;

  @override
  Future<Result<StoreProfile?, String>> getStoreProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      // 1. Cache-first (only if not forcing refresh)
      if (!forceRefresh) {
        final cached = await _localDataSource.getCache();
        if (cached != null) return Ok(cached);
      }

      // 2. Fetch from API
      final profile = await _remoteDataSource.fetchStoreProfile();
      if (profile == null) return const Ok(null);

      // 3. Update cache
      await _localDataSource.setCache(profile);

      return Ok(profile);
    } catch (e) {
      AppLogger.error('無法載入店家資料', e);
      return const Err('無法載入店家資料，請稍後再試');
    }
  }

  @override
  Future<Result<void, String>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
    final File? logoFile,
  }) async {
    try {
      StoreProfile finalTarget = target;

      // Handle Logo Upload
      if (logoFile != null) {
        final newLogoPath = await _remoteDataSource.uploadLogo(logoFile);
        finalTarget = target.copyWith(logoPath: newLogoPath);
      }

      final hasChanges = original != finalTarget;

      if (!hasChanges) {
        return const Ok(null);
      }

      final updatedProfile = await _remoteDataSource.updateStoreProfile(
        StoreProfileModel.fromEntity(finalTarget),
      );

      await _localDataSource.setCache(updatedProfile);

      // Clean up old logo if changed
      if (logoFile != null &&
          original.logoPath != null &&
          original.logoPath!.isNotEmpty) {
        // Fire and forget
        _remoteDataSource.deleteLogo(original.logoPath!);
        // We no longer manually delete from local cache as we use network image cache
      }

      return const Ok(null);
    } catch (e) {
      AppLogger.error('店家資料更新失敗', e);

      return const Err('店家資料更新失敗，請稍後再試');
    }
  }

  @override
  Future<Result<String, String>> getStoreId() async {
    try {
      // 1. 嘗試從本地快取獲取
      final cached = await _localDataSource.getCache();
      if (cached != null) return Ok(cached.id);

      // 2. 本地無快取 -> 從遠端獲取（會自動更新本地快取）
      final profile = await _remoteDataSource.fetchStoreProfile();
      if (profile == null) return const Err('找不到店家資料，請先完成店家設定');

      await _localDataSource.setCache(profile);

      return Ok(profile.id);
    } catch (e) {
      AppLogger.error('無法獲取店家 ID', e);
      return const Err('無法獲取店家 ID，請稍後再試');
    }
  }
}
