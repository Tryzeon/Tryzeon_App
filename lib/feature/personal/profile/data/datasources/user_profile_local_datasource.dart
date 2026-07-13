import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileLocalDataSource {
  UserProfileLocalDataSource(
    this._isarService,
    this._cacheService,
    this._cacheEntryLocalDataSource,
  );
  final IsarService _isarService;
  final CacheService _cacheService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = PersonalMappr();
  static const cacheKey = 'user_profile';

  Future<CacheLookup<UserProfileModel>> getUserProfile() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKey,
      staleDuration: AppConstants.staleDurationUserProfile,
    );
    if (cacheStatus == null) return const CacheMiss();

    final collection = await isar.userProfileCaches.where().findFirst();
    if (collection == null) return const CacheMiss();

    final model = _mappr.convert<UserProfileCache, UserProfileModel>(collection);
    return CacheHit(model);
  }

  Future<void> saveUserProfile(final UserProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.userProfileCaches.clear();
      final collection = _mappr.convert<UserProfileModel, UserProfileCache>(profile);
      await isar.userProfileCaches.put(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(cacheKey);
  }

  Future<File?> getAvatar(final String path) {
    return _cacheService.getImage(path);
  }

  Future<void> saveAvatar(final Uint8List bytes, final String path) {
    return _cacheService.saveImage(bytes, path);
  }

  Future<File?> downloadAvatar(final String path, final String downloadUrl) {
    return _cacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteAvatar(final String path) {
    return _cacheService.deleteImage(path);
  }
}
