import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/domain/services/cache_service.dart';
import 'package:tryzeon/feature/store/data/mappers/store_mappr.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileLocalDataSource {
  StoreProfileLocalDataSource(
    this._isarService,
    this._cacheService,
    this._cacheEntryLocalDataSource,
  );

  final IsarService _isarService;
  final CacheService _cacheService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;
  static const _mappr = StoreMappr();
  static const cacheKey = 'store_profile';

  Future<CacheLookup<StoreProfileModel>> getStoreProfile() async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      cacheKey,
      staleDuration: AppConstants.staleDurationStoreProfile,
    );
    if (cacheStatus == null) return const CacheMiss();

    if (cacheStatus == CacheEntryStatus.empty) {
      return const CacheEmpty();
    }

    final collection = await isar.storeProfileCaches.where().findFirst();
    if (collection == null) return const CacheMiss();

    final model = _mappr.convert<StoreProfileCache, StoreProfileModel>(collection);
    return CacheHit(model);
  }

  Future<void> saveStoreProfile(final StoreProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCaches.clear();
      final collection = _mappr.convert<StoreProfileModel, StoreProfileCache>(
        profile,
      );
      await isar.storeProfileCaches.put(collection);
    });
    await _cacheEntryLocalDataSource.markHasData(cacheKey);
  }

  Future<void> markStoreProfileAbsent() async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCaches.clear();
    });
    await _cacheEntryLocalDataSource.markEmpty(cacheKey);
  }

  Future<File?> getLogo(final String path) {
    return _cacheService.getImage(path);
  }

  Future<File?> downloadLogo(final String path, final String downloadUrl) {
    return _cacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> saveLogo(final Uint8List bytes, final String path) {
    return _cacheService.saveImage(bytes, path);
  }

  Future<void> deleteLogo(final String path) {
    return _cacheService.deleteImage(path);
  }
}
