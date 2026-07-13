import 'package:tryzeon/core/data/services/store_images_api.dart';

/// Adds a derived public `logo_url` to a store-profile row from its `logo_path`.
Map<String, dynamic> withStoreLogoUrl(final Map<String, dynamic> store) {
  final map = Map<String, dynamic>.from(store);
  final logoPath = map['logo_path'] as String?;
  if (logoPath != null && logoPath.isNotEmpty) {
    map['logo_url'] = StoreImagesApi.publicUrl(logoPath);
  }
  return map;
}

/// Enriches a raw `list_shop_products` row with derived image URLs so it can be
/// parsed by [ShopProductModel.fromJson]. Product and store-logo images use
/// deterministic public URLs (no signing, no network).
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
