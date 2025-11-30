import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products_info';
  static const _productImagesBucket = 'store';
  static const _cacheKey = 'products_cache';

  /// 獲取店家的所有商品
  static Future<Result<List<Product>>> getProducts({
    final String sortBy = 'created_at',
    final bool ascending = false,
    final bool forceRefresh = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('請重新登入');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final List<Product> products = cachedData
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
          .eq('store_id', user.id);

      await CacheService.saveList(_cacheKey, response);

      final List<Product> products = response.map(Product.fromJson).toList();
      return Result.success(data: _sortProducts(products, sortBy, ascending));
    } catch (e) {
      return Result.failure('獲取商品列表失敗', error: e);
    }
  }

  /// 創建新商品
  static Future<Result<List<Product>>> createProduct({
    required final String name,
    required final List<String> types,
    required final int price,
    required final String purchaseLink,
    required final File imageFile,
    final List<ProductSize> sizes = const [],
  }) async {
    try {
      // 獲取當前用戶 ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('請重新登入');
      }

      // 如果有圖片，先上傳圖片
      final String filePath = await _uploadProductImage(imageFile) ?? '';

      // 創建商品資料
      final product = Product(
        storeId: user.id,
        name: name,
        types: types,
        price: price,
        purchaseLink: purchaseLink,
        imagePath: filePath,
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
      return Result.failure('創建商品失敗', error: e);
    }
  }

  /// 更新商品
  static Future<Result<List<Product>>> updateProduct({
    required final String productId,
    required final String name,
    required final List<String> types,
    required final int price,
    required final String purchaseLink,
    required final String currentFilePath,
    final File? newImageFile,
  }) async {
    try {
      String? filePath = currentFilePath;

      // 如果有新圖片，上傳新圖片並刪除舊圖片
      if (newImageFile != null) {
        // 上傳新圖片
        final newFilePath = await _uploadProductImage(newImageFile);

        // 如果新圖片上傳成功，刪除舊圖片
        if (newFilePath != null && currentFilePath.isNotEmpty) {
          await _deleteProductImage(currentFilePath);
        }

        filePath = newFilePath;
      }

      final updateData = {
        'name': name,
        'type': types,
        'price': price,
        'image_path': filePath,
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
      return Result.failure('更新商品失敗', error: e);
    }
  }

  /// 刪除商品
  static Future<Result<List<Product>>> deleteProduct(
    final Product product,
  ) async {
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
      return Result.failure('刪除商品失敗', error: e);
    }
  }

  /// 載入商品圖片（優先從本地獲取，本地沒有才從後端拿）
  static Future<Result<File>> loadProductImage(final String filePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedFile = await CacheService.getImage(filePath);
      if (cachedFile != null && await cachedFile.exists()) {
        return Result.success(data: cachedFile);
      }

      // 2. 本地沒有，從 Supabase 下載並保存到本地緩存
      final bytes = await _supabase.storage
          .from(_productImagesBucket)
          .download(filePath);
      final savedFile = await CacheService.saveImage(bytes, filePath);

      return Result.success(data: savedFile);
    } catch (e) {
      return Result.failure('載入商品圖片失敗', error: e);
    }
  }

  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String?> _uploadProductImage(final File imageFile) async {
    final storeId = _supabase.auth.currentUser?.id;
    if (storeId == null) return null;

    // 生成唯一的檔案名稱
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageName = '$timestamp.jpg';
    final filePath = '$storeId/products/$imageName';

    final bytes = await imageFile.readAsBytes();

    // 上傳到 Supabase Storage
    await _supabase.storage
        .from(_productImagesBucket)
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    // 保存到本地緩存
    await CacheService.saveImage(bytes, filePath);

    // 返回檔案路徑
    return filePath;
  }

  /// 刪除商品圖片（Supabase 和本地）
  static Future<void> _deleteProductImage(final String filePath) async {
    if (filePath.isEmpty) return;

    // 1. 刪除 Supabase Storage 中的圖片
    await _supabase.storage.from(_productImagesBucket).remove([filePath]);

    // 2. 刪除本地緩存的圖片
    await CacheService.deleteImage(filePath);
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
