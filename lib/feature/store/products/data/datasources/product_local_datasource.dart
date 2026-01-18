import 'dart:typed_data';

import 'package:isar/isar.dart';
import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ProductLocalDataSource {
  ProductLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductModel>?> getCache() async {
    final isar = await _isarService.db;
    final collections = await isar.productCollections.where().findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) {
      return ProductModel(
        id: e.productId,
        storeId: e.storeId,
        name: e.name,
        price: e.price ?? 0.0,
        imagePath: e.imagePath ?? '',
        imageUrl: e.imageUrl ?? '',
        types: e.types?.toSet() ?? {},
        sizes: e.sizes
            ?.map(
              (final s) => ProductSizeModel(
                id: s.id,
                productId: s.productId,
                name: s.name ?? '',
                measurements: BodyMeasurements(
                  height: s.height,
                  weight: s.weight,
                  shoulderWidth: s.shoulderWidth,
                  chest: s.chest,
                  waist: s.waist,
                  hips: s.hips,
                  sleeveLength: s.sleeveLength,
                ),
                createdAt: s.createdAt,
                updatedAt: s.updatedAt,
              ),
            )
            .toList(),
        purchaseLink: e.purchaseLink,
        tryonCount: e.tryonCount,
        purchaseClickCount: e.purchaseClickCount,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
        storeName: e.storeName,
      );
    }).toList();
  }

  Future<void> setCache(final List<ProductModel> models) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCollections.clear();
      final collections = models.map((final e) {
        return ProductCollection()
          ..productId = e.id ?? ''
          ..storeId = e.storeId
          ..name = e.name
          ..price = e.price
          ..imagePath = e.imagePath
          ..imageUrl = e.imageUrl
          ..types = e.types.toList()
          ..purchaseLink = e.purchaseLink
          ..tryonCount = e.tryonCount
          ..purchaseClickCount = e.purchaseClickCount
          ..createdAt = e.createdAt
          ..updatedAt = e.updatedAt
          ..storeName = e.storeName
          ..sizes = e.sizes
              ?.map(
                (final s) => ProductSizeCollection()
                  ..id = s.id
                  ..productId = s.productId
                  ..name = s.name
                  ..height = s.measurements.height
                  ..weight = s.measurements.weight
                  ..chest = s.measurements.chest
                  ..waist = s.measurements.waist
                  ..hips = s.measurements.hips
                  ..shoulderWidth = s.measurements.shoulderWidth
                  ..sleeveLength = s.measurements.sleeveLength
                  ..createdAt = s.createdAt
                  ..updatedAt = s.updatedAt,
              )
              .toList();
      }).toList();

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
