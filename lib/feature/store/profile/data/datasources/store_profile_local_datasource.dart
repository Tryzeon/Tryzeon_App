import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_collection.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileLocalDataSource {
  StoreProfileLocalDataSource(this._isarService);

  final IsarService _isarService;

  Future<StoreProfileModel?> getCache() async {
    final isar = await _isarService.db;
    final collection = await isar.storeProfileCollections.where().findFirst();
    if (collection == null) return null;

    return StoreProfileModel(
      id: collection.storeId,
      ownerId: collection.ownerId,
      name: collection.name,
      address: collection.address,
      logoPath: collection.logoPath,
      logoUrl: collection.logoUrl,
      createdAt: collection.createdAt,
      updatedAt: collection.updatedAt,
    );
  }

  Future<void> setCache(final StoreProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.storeProfileCollections.clear();
      final collection = StoreProfileCollection()
        ..storeId = profile.id
        ..ownerId = profile.ownerId
        ..name = profile.name
        ..address = profile.address
        ..logoPath = profile.logoPath
        ..logoUrl = profile.logoUrl
        ..createdAt = profile.createdAt
        ..updatedAt = profile.updatedAt;
      await isar.storeProfileCollections.put(collection);
    });
  }

  Future<void> saveLogo(final Uint8List bytes, final String path) {
    return CacheService.saveImage(bytes, path);
  }

  Future<File?> getCachedLogo(final String path) {
    return CacheService.getImage(path);
  }

  Future<File?> downloadLogo(final String path, final String downloadUrl) {
    return CacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteLogo(final String path) {
    return CacheService.deleteImage(path);
  }
}
