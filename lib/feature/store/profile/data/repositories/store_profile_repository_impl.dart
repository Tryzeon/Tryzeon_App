import 'dart:io';

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
  Future<Result<StoreProfile?, String>> getStoreProfile() async {
    try {
      // Cache-first
      final cached = _localDataSource.cache;
      if (cached != null) return Ok(cached);

      // Fetch from API
      final json = await _remoteDataSource.fetchStoreProfile();
      if (json == null) return const Ok(null);

      final entity = StoreProfileModel.fromJson(json);

      // Update cache
      _localDataSource.cache = entity;

      return Ok(entity);
    } catch (e) {
      if (e is String) return Err(e);
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

        // Optimistic cache update for image
        final bytes = await logoFile.readAsBytes();
        await _localDataSource.saveLogo(bytes, newLogoPath);
      }

      final updateData = original.getDirtyFields(finalTarget);
      if (updateData.isEmpty) return const Ok(null);

      final updatedJson = await _remoteDataSource.updateStoreProfile(updateData);
      final updated = StoreProfileModel.fromJson(updatedJson);

      _localDataSource.cache = updated;

      // Clean up old logo if changed
      if (logoFile != null &&
          original.logoPath != null &&
          original.logoPath!.isNotEmpty) {
        // Fire and forget
        _remoteDataSource.deleteLogo(original.logoPath!);
        _localDataSource.deleteLogo(original.logoPath!);
      }

      return const Ok(null);
    } catch (e) {
      if (e is String) return Err(e);
      return const Err('店家資料更新失敗，請稍後再試');
    }
  }

  @override
  Future<Result<File, String>> getStoreLogo(final String path) async {
    try {
      // 1. Try Local Cache
      final cachedLogo = await _localDataSource.getCachedLogo(path);
      if (cachedLogo != null) {
        return Ok(cachedLogo);
      }

      // 2. If missing, generate URL and download
      final url = _remoteDataSource.getLogoPublicUrl(path);
      final downloadedLogo = await _localDataSource.downloadLogo(path, url);

      if (downloadedLogo == null) {
        return const Err('無法獲取 Logo 圖片，請稍後再試');
      }

      return Ok(downloadedLogo);
    } catch (e) {
      return const Err('無法載入店家 Logo ，請稍後再試');
    }
  }
}
