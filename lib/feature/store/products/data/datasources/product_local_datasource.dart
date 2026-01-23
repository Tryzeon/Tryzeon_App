import 'dart:typed_data';

import 'package:isar_community/isar.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/mappers/product_mapper.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductModel>?> getCache({required final SortCondition sort}) async {
    final isar = await _isarService.db;

    // 檢查是否有資料
    if (await isar.productCollections.count() == 0) return null;

    final q = isar.productCollections.where();
    List<ProductCollection> collections;

    switch (sort.field) {
      case SortField.name:
        collections = await (sort.ascending ? q.sortByName() : q.sortByNameDesc())
            .findAll();
        break;
      case SortField.price:
        collections = await (sort.ascending ? q.sortByPrice() : q.sortByPriceDesc())
            .findAll();
        break;
      case SortField.createdAt:
        collections =
            await (sort.ascending ? q.sortByCreatedAt() : q.sortByCreatedAtDesc())
                .findAll();
        break;
      case SortField.updatedAt:
        collections =
            await (sort.ascending ? q.sortByUpdatedAt() : q.sortByUpdatedAtDesc())
                .findAll();
        break;
      case SortField.tryonCount:
        collections =
            await (sort.ascending ? q.sortByTryonCount() : q.sortByTryonCountDesc())
                .findAll();
        break;
      case SortField.purchaseClickCount:
        collections =
            await (sort.ascending
                    ? q.sortByPurchaseClickCount()
                    : q.sortByPurchaseClickCountDesc())
                .findAll();
        break;
    }

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
