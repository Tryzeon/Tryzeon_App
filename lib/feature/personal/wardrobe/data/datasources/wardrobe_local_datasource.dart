import 'dart:io';
import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_collection.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/mappers/wardrobe_item_mapper.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';

class WardrobeLocalDataSource {
  WardrobeLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<WardrobeItemModel>?> getCachedItems() async {
    final isar = await _isarService.db;
    final collections = await isar.wardrobeItemCollections
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) => e.toModel()).toList();
  }

  Future<void> updateCachedItems(final List<WardrobeItemModel> items) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.clear();
      final collections = items.map((final e) => e.toCollection()).toList();
      await isar.wardrobeItemCollections.putAll(collections);
    });
  }

  Future<void> addItemToCache(final WardrobeItemModel item) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.put(item.toCollection());
    });
  }

  Future<void> removeItemFromCache(final String id) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.wardrobeItemCollections.deleteByItemId(id);
    });
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
