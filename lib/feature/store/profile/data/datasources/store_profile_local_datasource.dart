import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class StoreProfileLocalDataSource {
  StoreProfile? _cachedStoreProfile;

  StoreProfile? get cache => _cachedStoreProfile;

  set cache(final StoreProfile profile) {
    _cachedStoreProfile = profile;
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
