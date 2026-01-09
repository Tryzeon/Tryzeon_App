import 'dart:typed_data';

import 'package:tryzeon/core/services/cache_service.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ProductLocalDataSource {
  List<ProductModel>? cache;

  Future<void> saveProductImage(final Uint8List bytes, final String path) async {
    await CacheService.saveImage(bytes, path);
  }

  Future<void> deleteProductImage(final String path) async {
    await CacheService.deleteImage(path);
  }
}
