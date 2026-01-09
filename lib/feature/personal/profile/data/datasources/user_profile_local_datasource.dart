import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileLocalDataSource {
  UserProfileModel? _cachedProfile;

  UserProfileModel? getCache() => _cachedProfile;

  void setCache(final UserProfileModel profile) {
    _cachedProfile = profile;
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
