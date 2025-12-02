import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';
  static const _productImagesBucket = 'store';
  static const _cacheKey = 'products_cache';

  /// 獲取店家的所有商品
  static Future<Result<List<Product>>> getProducts({
    final String sortBy = 'created_at',
    final bool ascending = false,
    final bool forceRefresh = false,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadFromCache(_cacheKey);
        if (cachedData != null) {
          final List<Product> cachedProducts = cachedData
              .map(
                (final json) => Product.fromJson(Map<String, dynamic>.from(json as Map)),
              )
              .toList()
              .cast<Product>();
          return Result.success(data: _sortProducts(cachedProducts, sortBy, ascending));
        }
      }

      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('store_id', store.id);

      await CacheService.saveToCache(_cacheKey, response);

      final List<Product> products = response.map(Product.fromJson).toList();
      return Result.success(data: _sortProducts(products, sortBy, ascending));
    } catch (e) {
      return Result.failure('商品列表獲取失敗', error: e);
    }
  }

  /// 創建新商品
  static Future<Result<void>> createProduct({
    required final String name,
    required final List<String> types,
    required final int price,
    required final String purchaseLink,
    required final File image,
    final List<ProductSize> sizes = const [],
  }) async {
    try {
      // 獲取當前用戶 ID
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 如果有圖片，先上傳圖片
      final String imagePath = await _uploadProductImage(store, image);

      // 商品創建資料
      final product = Product(
        storeId: store.id,
        name: name,
        types: types,
        price: price,
        imagePath: imagePath,
        purchaseLink: purchaseLink,
      );

      final response = await _supabase
          .from(_productsTable)
          .insert(product.toJson())
          .select()
          .single();

      final productId = response['id'];

      if (sizes.isNotEmpty) {
        final sizesData = sizes.map((final size) {
          return {
            'product_id': productId,
            'name': size.name,
            ...size.measurements.toJson(),
          };
        }).toList();

        await _supabase.from('product_sizes').insert(sizesData);
      }

      // 清除快取以確保下次獲取最新資料
      await CacheService.deleteCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('商品創建失敗', error: e);
    }
  }

  /// 更新商品
  static Future<Result<void>> updateProduct({
    required final Product product,
    required final String name,
    required final List<String> types,
    required final int price,
    required final String purchaseLink,
    final File? newProductImage,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      String? productImagePath = product.imagePath;

      if (newProductImage != null) {
        await _deleteProductImage(productImagePath);
        productImagePath = await _uploadProductImage(store, newProductImage);
      }

      final updateData = {
        'name': name,
        'type': types,
        'price': price,
        'image_path': productImagePath,
        'purchase_link': purchaseLink,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from(_productsTable).update(updateData).eq('id', product.id!);

      // 清除快取以確保下次獲取最新資料
      await CacheService.deleteCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('商品更新失敗', error: e);
    }
  }

  /// 刪除商品
  static Future<Result<void>> deleteProduct(final Product product) async {
    try {
      // 刪除圖片（Supabase Storage 和本地）
      if (product.imagePath.isNotEmpty) {
        await _deleteProductImage(product.imagePath);
      }

      // 刪除商品資料
      await _supabase.from(_productsTable).delete().eq('id', product.id!);

      // 清除快取以確保下次獲取最新資料
      await CacheService.deleteCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('商品刪除失敗', error: e);
    }
  }

  /// 載入商品圖片（優先從本地獲取，本地沒有才從後端拿）
  static Future<Result<File>> getProductImage(final String imagePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedProductImage = await CacheService.getImage(imagePath);
      if (cachedProductImage != null) {
        return Result.success(data: cachedProductImage);
      }

      // 2. 本地沒有，從 Supabase 取得 Public URL 下載
      final url = _supabase.storage.from(_productImagesBucket).getPublicUrl(imagePath);

      final productImage = await CacheService.getImage(imagePath, downloadUrl: url);

      return Result.success(data: productImage);
    } catch (e) {
      return Result.failure('商品圖片載入失敗', error: e);
    }
  }

  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String> _uploadProductImage(final store, final File image) async {
    // 生成唯一的檔案名稱
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageName = '$timestamp.jpg';
    final productImagePath = '${store.id}/products/$imageName';

    final bytes = await image.readAsBytes();

    // 上傳到 Supabase Storage
    await _supabase.storage
        .from(_productImagesBucket)
        .uploadBinary(
          productImagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    // 保存到本地緩存
    await CacheService.saveImage(bytes, productImagePath);

    // 返回檔案路徑
    return productImagePath;
  }

  /// 刪除商品圖片（Supabase 和本地）
  static Future<void> _deleteProductImage(final String imagePath) async {
    if (imagePath.isEmpty) return;

    // 1. 刪除 Supabase Storage 中的圖片
    await _supabase.storage.from(_productImagesBucket).remove([imagePath]);

    // 2. 刪除本地緩存的圖片
    await CacheService.deleteImage(imagePath);
  }

  /// 本地排序產品
  static List<Product> _sortProducts(
    final List<Product> products,
    final String sortBy,
    final bool ascending,
  ) {
    final sortedProducts = List<Product>.from(products);

    sortedProducts.sort((final a, final b) {
      int comparison;

      switch (sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'price':
          comparison = a.price.compareTo(b.price);
          break;
        case 'created_at':
          comparison = a.createdAt!.compareTo(b.createdAt!);
          break;
        case 'updated_at':
          comparison = a.updatedAt!.compareTo(b.updatedAt!);
          break;
        default:
          comparison = 0;
      }

      return ascending ? comparison : -comparison;
    });

    return sortedProducts;
  }
}
