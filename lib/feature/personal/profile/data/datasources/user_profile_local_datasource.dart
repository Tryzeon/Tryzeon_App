import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_collection.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileLocalDataSource {
  UserProfileLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<UserProfileModel?> getCache() async {
    final isar = await _isarService.db;
    final collection = await isar.userProfileCollections.where().findFirst();
    if (collection == null) return null;

    final measurements = collection.measurements;
    return UserProfileModel(
      userId: collection.userId,
      name: collection.name ?? '',
      avatarPath: collection.avatarPath,
      measurements: BodyMeasurements(
        height: measurements?.height,
        weight: measurements?.weight,
        shoulderWidth: measurements?.shoulderWidth,
        chest: measurements?.chest,
        waist: measurements?.waist,
        hips: measurements?.hips,
        sleeveLength: measurements?.sleeveLength,
      ),
    );
  }

  Future<void> setCache(final UserProfileModel profile) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.userProfileCollections.clear();
      final collection = UserProfileCollection()
        ..userId = profile.userId
        ..name = profile.name
        ..avatarPath = profile.avatarPath
        ..measurements = (BodyMeasurementsCollection()
          ..height = profile.measurements.height
          ..weight = profile.measurements.weight
          ..shoulderWidth = profile.measurements.shoulderWidth
          ..chest = profile.measurements.chest
          ..waist = profile.measurements.waist
          ..hips = profile.measurements.hips
          ..sleeveLength = profile.measurements.sleeveLength);

      await isar.userProfileCollections.put(collection);
    });
  }

  Future<void> saveAvatar(final Uint8List bytes, final String path) {
    return CacheService.saveImage(bytes, path);
  }

  Future<File?> getCachedAvatar(final String path) {
    return CacheService.getImage(path);
  }

  Future<File?> downloadAvatar(final String path, final String downloadUrl) {
    return CacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteAvatar(final String path) {
    return CacheService.deleteImage(path);
  }
}
