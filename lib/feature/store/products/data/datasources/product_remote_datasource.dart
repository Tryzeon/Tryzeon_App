import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/store/products/data/models/product_model.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productsTable = 'products';
  static const _productSizesTable = 'product_sizes';
  static const _productImagesBucket = 'store';

  Future<List<ProductModel>> fetchProducts() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from('store_profile')
        .select('''
          id,
          products(
            *,
            product_sizes(*)
          )
        ''')
        .eq('owner_id', user.id)
        .single();

    final products = response['products'] as List;
    return products.map((final e) {
      final map = Map<String, dynamic>.from(e);
      final imagePath = map['image_path'] as String?;
      if (imagePath != null) {
        map['image_url'] = getProductImageUrl(imagePath);
      }
      return ProductModel.fromJson(map);
    }).toList();
  }

  Future<String> getStoreId() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from('store_profile')
        .select('id')
        .eq('owner_id', user.id)
        .single();

    return response['id'] as String;
  }

  Future<String> insertProduct(final Map<String, dynamic> productData) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .insert(productData)
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> insertProductSizes(final List<Map<String, dynamic>> sizesData) async {
    await _supabaseClient.from(_productSizesTable).insert(sizesData);
  }

  Future<ProductModel> fetchProduct(final String productId) async {
    final response = await _supabaseClient
        .from(_productsTable)
        .select('*, product_sizes(*)')
        .eq('id', productId)
        .single();

    final map = Map<String, dynamic>.from(response);
    final imagePath = map['image_path'] as String?;
    if (imagePath != null) {
      map['image_url'] = getProductImageUrl(imagePath);
    }
    return ProductModel.fromJson(map);
  }

  Future<void> updateProduct(
    final String productId,
    final Map<String, dynamic> updateData,
  ) async {
    await _supabaseClient.from(_productsTable).update(updateData).eq('id', productId);
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

  Future<void> insertProductSize(final Map<String, dynamic> sizeData) async {
    await _supabaseClient.from(_productSizesTable).insert(sizeData);
  }

  Future<void> updateProductSize(
    final String sizeId,
    final Map<String, dynamic> dirtyFields,
  ) async {
    await _supabaseClient.from(_productSizesTable).update(dirtyFields).eq('id', sizeId);
  }

  Future<String> uploadProductImage(final File image) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final imageName = p.basename(image.path);
    final productImagePath = '${user.id}/products/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_productImagesBucket)
        .uploadBinary(
          productImagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );

    return productImagePath;
  }

  Future<void> deleteProductImage(final String imagePath) async {
    if (imagePath.isEmpty) return;
    await _supabaseClient.storage.from(_productImagesBucket).remove([imagePath]);
  }

  String getProductImageUrl(final String imagePath) {
    if (imagePath.isEmpty) return '';
    return _supabaseClient.storage.from(_productImagesBucket).getPublicUrl(imagePath);
  }
}
