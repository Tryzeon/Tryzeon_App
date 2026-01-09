import 'dart:io';
import 'dart:typed_data';
import 'package:tryzeon/core/services/cache_service.dart';
import '../../domain/entities/wardrobe_item.dart';

class WardrobeLocalDataSource {
  List<WardrobeItem>? _cachedItems;

  List<WardrobeItem>? getCachedItems() => _cachedItems;

  void updateCachedItems(final List<WardrobeItem> items) {
    _cachedItems = items;
  }

  void addItemToCache(final WardrobeItem item) {
    if (_cachedItems == null) {
      _cachedItems = [item];
    } else {
      _cachedItems = [item, ..._cachedItems!];
    }
  }

  void removeItemFromCache(final String id) {
    _cachedItems?.removeWhere((final item) => item.id == id);
  }

  Future<void> saveImage(final Uint8List bytes, final String path) {
    return CacheService.saveImage(bytes, path);
  }

  Future<File?> getImage(final String path, {final String? downloadUrl}) {
    return CacheService.getImage(path, downloadUrl: downloadUrl);
  }

  Future<void> deleteImage(final String path) {
    return CacheService.deleteImage(path);
  }
}
