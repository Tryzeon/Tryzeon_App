import 'dart:io';
import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_collection.dart';
import 'package:tryzeon/feature/personal/profile/data/mappers/user_profile_mapper.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileLocalDataSource {
  UserProfileLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<UserProfileModel?> getCache() async {
    final isar = await _isarService.db;
    final collection = await isar.userProfileCollections.where().findFirst();
    return collection?.toModel();
  }

  Future<void> setCache(final UserProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.userProfileCollections.clear();
      await isar.userProfileCollections.put(profile.toCollection());
    });
  }

  Future<File?> getAvatar(final String path) {
    return CacheService.getImage(path);
  }

  Future<void> saveAvatar(final Uint8List bytes, final String path) {
    return CacheService.saveImage(bytes, path);
  }

  Future<File?> downloadAvatar(final String path, final String downloadUrl) {
    return CacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteAvatar(final String path) {
    return CacheService.deleteImage(path);
  }
}
