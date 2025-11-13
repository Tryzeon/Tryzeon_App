import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product_model.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products_info';
  static const _productImagesBucket = 'store';

  static const _cacheKey = 'products_cache';

  /// 獲取店家的所有商品
  static Future<ProductResult> getProducts({
    String sortBy = 'created_at',
    bool ascending = false,
    bool forceRefresh = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ProductResult.failure('用戶未登入');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          List<Product> products = cachedData.map((json) => Product.fromJson(json)).toList();
          return ProductResult.success(_sortProducts(products, sortBy, ascending));
        }
      }

      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('store_id', user.id);

      await CacheService.saveList(_cacheKey, response);

      List<Product> products = response.map((json) => Product.fromJson(json)).toList();
      return ProductResult.success(_sortProducts(products, sortBy, ascending));
    } catch (e) {
      return ProductResult.failure(e.toString());
    }
  }

  /// 創建新商品
  static Future<ProductResult> createProduct({
    required String name,
    required List<String> types,
    required int price,
    required String purchaseLink,
    required File imageFile,
  }) async {
    try {
      // 獲取當前用戶 ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return ProductResult.failure('用戶未登入');
      }

      // 如果有圖片，先上傳圖片
      String filePath = await _uploadProductImage(imageFile) ?? '';

      // 創建商品資料
      final product = Product(
        storeId: user.id,
        name: name,
        types: types,
        price: price,
        purchaseLink: purchaseLink,
        imagePath: filePath,
      );

      // 插入到資料庫
      await _supabase
          .from(_productsTable)
          .insert(product.toJson());

      // 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return ProductResult.success();
    } catch (e) {
      return ProductResult.failure(e.toString());
    }
  }

  /// 更新商品
  static Future<ProductResult> updateProduct({
    required String productId,
    required String name,
    required List<String> types,
    required int price,
    required String purchaseLink,
    required String currentFilePath,
    File? newImageFile
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

      return ProductResult.success();
    } catch (e) {
      return ProductResult.failure(e.toString());
    }
  }

  /// 刪除商品
  static Future<ProductResult> deleteProduct(Product product) async {
    try {
      // 刪除圖片（Supabase Storage 和本地）
      if (product.imagePath.isNotEmpty) {
        await _deleteProductImage(product.imagePath);
      }

      // 刪除商品資料
      await _supabase
          .from(_productsTable)
          .delete()
          .eq('id', product.id!);

      // 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return ProductResult.success();
    } catch (e) {
      return ProductResult.failure(e.toString());
    }
  }

  /// 載入商品圖片（優先從本地獲取，本地沒有才從後端拿）
  static Future<ProductResult> loadItemImage(String filePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final localFile = await CacheService.getImage(filePath);
      if (localFile != null && await localFile.exists()) {
        return ProductResult.successWithImage(localFile);
      }

      // 2. 本地沒有，從 Supabase 下載並保存到本地緩存
      final bytes = await _supabase.storage.from(_productImagesBucket).download(filePath);
      final savedFile = await CacheService.saveImage(bytes, filePath);

      return ProductResult.successWithImage(savedFile);
    } catch (e) {
      return ProductResult.failure('載入商品圖片失敗: ${e.toString()}');
    }
  }

  /// 本地排序產品
  static List<Product> _sortProducts(List<Product> products, String sortBy, bool ascending) {
    final sortedProducts = List<Product>.from(products);

    sortedProducts.sort((a, b) {
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

  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String?> _uploadProductImage(File imageFile) async {
    final storeId = _supabase.auth.currentUser?.id;
    if (storeId == null) return null;

    // 生成唯一的檔案名稱
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imageName = '$timestamp.jpg';
    final filePath = '$storeId/products/$imageName';

    final bytes = await imageFile.readAsBytes();

    // 上傳到 Supabase Storage
    await _supabase.storage.from(_productImagesBucket).uploadBinary(
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
  static Future<void> _deleteProductImage(String filePath) async {
    if (filePath.isEmpty) return;

    // 1. 刪除 Supabase Storage 中的圖片
    await _supabase.storage
        .from(_productImagesBucket)
        .remove([filePath]);

    // 2. 刪除本地緩存的圖片
    await CacheService.deleteImage(filePath);
  }
}

class ProductResult {
  final bool success;
  final List<Product>? products;
  final File? image;
  final String? errorMessage;

  ProductResult({
    required this.success,
    this.products,
    this.image,
    this.errorMessage,
  });

  factory ProductResult.success([List<Product>? products]) {
    return ProductResult(success: true, products: products);
  }

  factory ProductResult.successWithImage(File? image) {
    return ProductResult(success: true, image: image);
  }

  factory ProductResult.failure(String errorMessage) {
    return ProductResult(success: false, errorMessage: errorMessage);
  }
}