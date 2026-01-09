import 'dart:io';
import 'dart:typed_data';

import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/feature/store/profile/data/models/store_profile_model.dart';

class StoreProfileLocalDataSource {
  StoreProfileModel? _cachedStoreProfile;

  StoreProfileModel? getCache() => _cachedStoreProfile;

  void setCache(final StoreProfileModel profile) {
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
