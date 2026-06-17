import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/store_images_api.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_request.dart';
import 'package:tryzeon/feature/store/products/data/models/create_product_size_request.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._supabaseClient, this._storeImagesApi);

  final SupabaseClient _supabaseClient;
  final StoreImagesApi _storeImagesApi;
  static const _productsTable = AppConstants.tableProducts;
  static const _productSizesTable = AppConstants.tableProductVariants;

  Future<List<ProductModel>> listProducts({required final String storeId}) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('*, product_variants(*)')
        .eq('store_id', storeId);

    return (response as List).map((final e) {
      return ProductModel.fromJson(_withProductImageUrl(e));
    }).toList();
  }

  Future<void> insertProduct(final CreateProductRequest request) async {
    await _supabaseClient.from(_productsTable).insert(request.toJson());
  }

  Future<void> insertProductSizes(final List<CreateProductSizeRequest> requests) async {
    final sizesData = requests.map((final e) => e.toJson()).toList();
    await _supabaseClient.from(_productSizesTable).insert(sizesData);
  }

  Future<ProductModel> getProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('*, product_variants(*)')
        .eq('id', productId)
        .single();

    return ProductModel.fromJson(_withProductImageUrl(response));
  }

  Future<void> updateProduct(final ProductModel product) async {
    final json = product.toJson()
      ..remove('id')
      ..remove('store_id')
      ..remove('created_at')
      ..remove('updated_at')
      ..remove('product_variants');

    await _supabaseClient.from(_productsTable).update(json).eq('id', product.id);
  }

  Future<void> deleteProduct(final String productId) async {
    await _supabaseClient.from(_productsTable).delete().eq('id', productId);
  }

  Future<void> deleteProductSizes(final String productId) async {
    await _supabaseClient.from(_productSizesTable).delete().eq('product_id', productId);
  }

  Future<void> deleteProductSize(final String sizeId) async {
    await _supabaseClient.from(_productSizesTable).delete().eq('id', sizeId);
  }

  Future<void> insertProductSize(final CreateProductSizeRequest request) async {
    await _supabaseClient.from(_productSizesTable).insert(request.toJson());
  }

  Future<void> updateProductSize(final ProductSizeModel size) async {
    final json = size.toJson()
      ..remove('id')
      ..remove('product_id')
      ..remove('created_at')
      ..remove('updated_at');

    await _supabaseClient.from(_productSizesTable).update(json).eq('id', size.id);
  }

  Future<List<String>> uploadProductImages({
    required final String storeId,
    required final String productId,
    required final List<File> images,
  }) async {
    return _storeImagesApi.uploadProductImages(
      storeId: storeId,
      productId: productId,
      images: images,
    );
  }

  Future<void> deleteProductImages({
    required final String storeId,
    required final List<String> keys,
  }) async {
    return _storeImagesApi.deleteImages(storeId: storeId, keys: keys);
  }

  Map<String, dynamic> _withProductImageUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final rawPaths = map['image_paths'];
    final imagePaths = rawPaths != null ? List<String>.from(rawPaths) : <String>[];
    map['image_paths'] = imagePaths;
    map['image_urls'] = imagePaths.map(StoreImagesApi.publicUrl).toList();
    return map;
  }
}
