import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileLocalDataSource {
  UserProfile? _cachedProfile;

  UserProfile? get cache => _cachedProfile;

  set cache(final UserProfile profile) {
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
