import 'package:isar/isar.dart';
import 'package:tryzeon/core/services/isar_service.dart';
import 'package:tryzeon/feature/common/product_type/data/collections/product_type_collection.dart';
import 'package:tryzeon/feature/common/product_type/domain/entities/product_type.dart';

class ProductTypeLocalDataSource {
  ProductTypeLocalDataSource(this._isarService);
  final IsarService _isarService;

  Future<List<ProductType>?> getCached() async {
    final isar = await _isarService.db;
    final collections = await isar.productTypeCollections.where().findAll();
    if (collections.isEmpty) return null;

    return collections.map((final e) => ProductType(id: e.typeId, name: e.name)).toList();
  }

  Future<void> cache(final List<ProductType> types) async {
    final isar = await _isarService.db;
    await isar.writeTxn(() async {
      await isar.productTypeCollections.clear();
      final collections = types.map((final e) {
        return ProductTypeCollection()
          ..typeId = e.id
          ..name = e.name;
      }).toList();
      await isar.productTypeCollections.putAll(collections);
    });
  }
}
