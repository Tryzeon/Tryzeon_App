import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_type/data/collections/product_type_collection.dart';
import 'package:tryzeon/feature/common/product_type/data/mappers/product_type_mapper.dart';
import 'package:tryzeon/feature/common/product_type/data/models/product_type_model.dart';

class ProductTypeLocalDataSource {
  ProductTypeLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductTypeModel>?> getCached() async {
    final isar = await _isarService.db;
    final collections = await isar.productTypeCollections.where().findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) => e.toModel()).toList();
  }

  Future<void> cache(final List<ProductTypeModel> types) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productTypeCollections.clear();
      final collections = types.map((final e) => e.toCollection()).toList();
      await isar.productTypeCollections.putAll(collections);
    });
  }
}
