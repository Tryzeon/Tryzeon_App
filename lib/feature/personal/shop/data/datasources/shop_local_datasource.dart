import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/datasources/cache_entry_local_datasource.dart';
import 'package:tryzeon/core/data/services/isar_service.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/feature/common/measurements/data/collections/measurements_embedded.dart';
import 'package:tryzeon/feature/common/measurements/data/models/measurements_model.dart';
import 'package:tryzeon/feature/common/product_size/data/models/product_size_model.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_collection.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';

class ShopLocalDataSource {
  ShopLocalDataSource(this._isarService, this._cacheEntryLocalDataSource);

  final IsarService _isarService;
  final CacheEntryLocalDataSource _cacheEntryLocalDataSource;

  static String productCacheKey(final String productId) => 'shop_product:$productId';

  Future<void> saveProducts(final List<ShopProductModel> products) async {
    final isar = await _isarService.db;

    final collections = products.map((final model) {
      final storeInfo = ShopStoreInfoEmbedded()
        ..storeId = model.storeInfo.id
        ..name = model.storeInfo.name
        ..address = model.storeInfo.address
        ..logoUrl = model.storeInfo.logoUrl
        ..channels = model.storeInfo.channels
        ..orderContacts = model.storeInfo.orderContacts
            .map(
              (final c) => StoreOrderContactEmbedded()
                ..type = c.type
                ..value = c.value,
            )
            .toList();

      List<ProductSizeEmbedded>? sizes;
      if (model.sizes != null) {
        sizes = model.sizes!.map((final size) {
          final sizeEmbedded = ProductSizeEmbedded()
            ..sizeId = size.id
            ..productId = size.productId
            ..name = size.name
            ..createdAt = size.createdAt
            ..updatedAt = size.updatedAt;

          if (size.measurements != null) {
            sizeEmbedded.measurements = MeasurementsEmbedded()
              ..height = size.measurements!.height
              ..chest = size.measurements!.chest
              ..waist = size.measurements!.waist
              ..hips = size.measurements!.hips
              ..shoulder = size.measurements!.shoulder
              ..sleeve = size.measurements!.sleeve
              ..heightOffset = size.measurements!.heightOffset
              ..chestOffset = size.measurements!.chestOffset
              ..waistOffset = size.measurements!.waistOffset
              ..hipsOffset = size.measurements!.hipsOffset
              ..shoulderOffset = size.measurements!.shoulderOffset
              ..sleeveOffset = size.measurements!.sleeveOffset;
          }

          return sizeEmbedded;
        }).toList();
      }

      return ShopProductCollection()
        ..productId = model.id
        ..name = model.name
        ..price = model.price
        ..categoryIds = model.categoryIds
        ..imagePaths = model.imagePaths
        ..imageUrls = model.imageUrls
        ..purchaseLink = model.purchaseLink
        ..material = model.material
        ..elasticity = model.elasticity
        ..fit = model.fit
        ..thickness = model.thickness
        ..styles = model.styles
        ..seasons = model.seasons
        ..sizes = sizes
        ..createdAt = model.createdAt
        ..updatedAt = model.updatedAt
        ..storeInfo = storeInfo;
    }).toList();

    await isar.writeTxn(() async {
      await isar.shopProductCollections.putAll(collections);
    });

    for (final product in products) {
      await _cacheEntryLocalDataSource.markHasData(productCacheKey(product.id));
    }
  }

  Future<void> saveProduct(final ShopProductModel product) async {
    await saveProducts([product]);
  }

  Future<CacheLookup<ShopProductModel>> getProductById(final String productId) async {
    final isar = await _isarService.db;
    final cacheStatus = await _cacheEntryLocalDataSource.getEntryStatus(
      productCacheKey(productId),
      staleDuration: AppConstants.staleDurationShopProduct,
    );
    if (cacheStatus == null) return const CacheMiss();

    final collection = await isar.shopProductCollections.getByProductId(productId);

    if (collection == null) return const CacheMiss();

    final storeInfoModel = ShopStoreInfoModel(
      id: collection.storeInfo.storeId,
      name: collection.storeInfo.name,
      address: collection.storeInfo.address,
      logoUrl: collection.storeInfo.logoUrl,
      channels: collection.storeInfo.channels,
      orderContacts: collection.storeInfo.orderContacts
          .map((final e) => StoreOrderContactModel(type: e.type, value: e.value))
          .toList(),
    );

    List<ProductSizeModel>? sizes;
    if (collection.sizes != null) {
      sizes = collection.sizes!.map((final sizeEmbedded) {
        MeasurementsModel? measurements;
        if (sizeEmbedded.measurements != null) {
          final m = sizeEmbedded.measurements!;
          measurements = MeasurementsModel(
            height: m.height,
            chest: m.chest,
            waist: m.waist,
            hips: m.hips,
            shoulder: m.shoulder,
            sleeve: m.sleeve,
            heightOffset: m.heightOffset,
            chestOffset: m.chestOffset,
            waistOffset: m.waistOffset,
            hipsOffset: m.hipsOffset,
            shoulderOffset: m.shoulderOffset,
            sleeveOffset: m.sleeveOffset,
          );
        }

        return ProductSizeModel(
          id: sizeEmbedded.sizeId,
          productId: sizeEmbedded.productId,
          name: sizeEmbedded.name,
          measurements: measurements,
          createdAt: sizeEmbedded.createdAt,
          updatedAt: sizeEmbedded.updatedAt,
        );
      }).toList();
    }

    return CacheHit(
      ShopProductModel(
        storeInfo: storeInfoModel,
        name: collection.name,
        categoryIds: collection.categoryIds,
        price: collection.price,
        imagePaths: collection.imagePaths,
        imageUrls: collection.imageUrls,
        id: collection.productId,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
        purchaseLink: collection.purchaseLink,
        material: collection.material,
        elasticity: collection.elasticity,
        fit: collection.fit,
        thickness: collection.thickness,
        styles: collection.styles,
        seasons: collection.seasons,
        sizes: sizes,
      ),
    );
  }
}
