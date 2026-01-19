import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_categories/data/collections/product_category_collection.dart';
import 'package:tryzeon/feature/common/product_categories/data/mappers/product_category_mapper.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryLocalDataSource {
  ProductCategoryLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductCategoryModel>?> getCached() async {
    final isar = await _isarService.db;
    final collections = await isar.productCategoryCollections.where().findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) => e.toModel()).toList();
  }

  Future<void> cache(final List<ProductCategoryModel> categories) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productCategoryCollections.clear();
      final collections = categories.map((final e) => e.toCollection()).toList();
      await isar.productCategoryCollections.putAll(collections);
    });
  }
}
