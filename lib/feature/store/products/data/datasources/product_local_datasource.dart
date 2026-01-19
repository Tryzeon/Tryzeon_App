import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/mappers/product_mapper.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductModel>?> getCache() async {
    final isar = await _isarService.db;
    final collections = await isar.productCollections.where().findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) => e.toModel()).toList();
  }

  Future<void> setCache(final List<ProductModel> models) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCollections.clear();
      final collections = models.map((final e) => e.toCollection()).toList();

      await isar.productCollections.putAll(collections);
    });
  }

  Future<void> saveProductImage(final Uint8List bytes, final String path) async {
    await CacheService.saveImage(bytes, path);
  }

  Future<void> deleteProductImage(final String path) async {
    await CacheService.deleteImage(path);
  }
}
