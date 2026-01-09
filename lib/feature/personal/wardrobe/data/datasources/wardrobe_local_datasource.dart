import 'dart:io';
import 'dart:typed_data';
import 'package:tryzeon/core/services/cache_service.dart';
import '../models/wardrobe_item_model.dart';

class WardrobeLocalDataSource {
  List<WardrobeItemModel>? _cachedItems;

  List<WardrobeItemModel>? getCachedItems() => _cachedItems;

  void updateCachedItems(final List<WardrobeItemModel> items) {
    _cachedItems = items;
  }

  void addItemToCache(final WardrobeItemModel item) {
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
