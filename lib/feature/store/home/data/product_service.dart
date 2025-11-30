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
        final cachedProducts = await CacheService.loadList(_cacheKey);
        if (cachedProducts != null) {
          final List<Product> products = cachedProducts
              .map((final json) => Product.fromJson(json))
              .toList();
          return Result.success(
            data: _sortProducts(products, sortBy, ascending),
          );
        }
      }

      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('store_id', store.id);

      await CacheService.saveList(_cacheKey, response);

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
    required final File productImage,
    final List<ProductSize> sizes = const [],
  }) async {
    try {
      // 獲取當前用戶 ID
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 如果有圖片，先上傳圖片
      final String productImagePath = await _uploadProductImage(productImage) ?? '';

      // 商品創建資料
      final product = Product(
        storeId: store.id,
        name: name,
        types: types,
        price: price,
        purchaseLink: purchaseLink,
        imagePath: productImagePath,
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
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('商品創建失敗', error: e);
    }
  }

  /// 更新商品
  static Future<Result<void>> updateProduct({
    required final String productId,
    required final String name,
    required final List<String> types,
    required final int price,
    required final String purchaseLink,
    required final String currentProductImagePath,
    final File? newProductImage,
  }) async {
    try {
      String? productImagePath = currentProductImagePath;

      // 如果有新圖片，上傳新圖片並刪除舊圖片
      if (newProductImage != null) {
        // 上傳新圖片
        final newProductImagePath = await _uploadProductImage(newProductImage);

        // 如果新圖片上傳成功，刪除舊圖片
        if (newProductImagePath != null && currentProductImagePath.isNotEmpty) {
          await _deleteProductImage(currentProductImagePath);
        }

        productImagePath = newProductImagePath;
      }

      final updateData = {
        'name': name,
        'type': types,
        'price': price,
        'image_path': productImagePath,
        'purchase_link': purchaseLink,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(_productsTable)
          .update(updateData)
          .eq('id', productId);

      // 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

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
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('商品刪除失敗', error: e);
    }
  }

  /// 載入商品圖片（優先從本地獲取，本地沒有才從後端拿）
  static Future<Result<File>> loadProductImage(final String productImagePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedProductImage = await CacheService.getImage(productImagePath);
      if (cachedProductImage != null && await cachedProductImage.exists()) {
        return Result.success(data: cachedProductImage);
      }

      // 2. 本地沒有，從 Supabase 下載並保存到本地緩存
      final bytes = await _supabase.storage
          .from(_productImagesBucket)
          .download(productImagePath);
      final productImage = await CacheService.saveImage(bytes, productImagePath);

      return Result.success(data: productImage);
    } catch (e) {
      return Result.failure('商品圖片載入失敗', error: e);
    }
  }

  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String?> _uploadProductImage(final File productImage) async {
    final store = _supabase.auth.currentUser;
    if (store == null) return null;

    // 生成唯一的檔案名稱
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageName = '$timestamp.jpg';
    final productImagePath = '${store.id}/products/$imageName';

    final bytes = await productImage.readAsBytes();

    // 上傳到 Supabase Storage
    await _supabase.storage
        .from(_productImagesBucket)
        .uploadBinary(
          productImagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
          ),
        );

    // 保存到本地緩存
    await CacheService.saveImage(bytes, productImagePath);

    // 返回檔案路徑
    return productImagePath;
  }

  /// 刪除商品圖片（Supabase 和本地）
  static Future<void> _deleteProductImage(final String productImagePath) async {
    if (productImagePath.isEmpty) return;

    // 1. 刪除 Supabase Storage 中的圖片
    await _supabase.storage.from(_productImagesBucket).remove([productImagePath]);

    // 2. 刪除本地緩存的圖片
    await CacheService.deleteImage(productImagePath);
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
