import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

const _mappr = PersonalMappr();

ShopProduct decodeShopProductRow(final Map<String, dynamic> row) =>
    _mappr.convert<ShopProductModel, ShopProduct>(
      ShopProductModel.fromJson(productRowWithImageUrls(row)),
    );

Map<String, dynamic> withStoreLogoUrl(final Map<String, dynamic> store) {
  final map = Map<String, dynamic>.from(store);
  final logoPath = map['logo_path'] as String?;
  if (logoPath != null && logoPath.isNotEmpty) {
    map['logo_url'] = StoreImagesApi.publicUrl(logoPath);
  }
  return map;
}

/// Product and store-logo images use deterministic public URLs (no signing,
/// no network).
Map<String, dynamic> productRowWithImageUrls(final Map<String, dynamic> row) {
  final map = Map<String, dynamic>.from(row);

  final rawPaths = map['image_paths'];
  final imagePaths = rawPaths != null
      ? List<String>.from(rawPaths as Iterable<dynamic>)
      : <String>[];
  map['image_paths'] = imagePaths;
  map['image_urls'] = imagePaths.map(StoreImagesApi.publicUrl).toList();

  final store = map['store_profiles'];
  if (store != null) {
    map['store_profiles'] = withStoreLogoUrl(
      Map<String, dynamic>.from(store as Map<dynamic, dynamic>),
    );
  }
  return map;
}
