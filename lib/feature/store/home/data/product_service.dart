import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';
  static const _productSizesTable = 'product_sizes';
  static const _productImagesBucket = 'store';

  /// 獲取店家的所有商品 Query
  static Query<List<Product>> productsQuery() {
    final store = _supabase.auth.currentUser;
    final id = store?.id;

    return Query<List<Product>>(
      key: ['products', id],
      queryFn: fetchProducts,
      config: QueryConfig(
        storageDeserializer: (final dynamic json) {
          if (json == null) return [];
          return (json as List).map((final e) => Product.fromJson(e)).toList();
        },
      ),
    );
  }

  /// 獲取商品列表 (Internal Fetcher)
  static Future<List<Product>> fetchProducts() async {
    final store = _supabase.auth.currentUser;
    if (store == null) {
      throw '無法獲取使用者資訊，請重新登入';
    }

    final response = await _supabase
        .from(_productsTable)
        .select('*, product_sizes(*)')
        .eq('store_id', store.id);

    return response
        .map((final e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .toList()
        .cast<Product>();
  }

  /// 創建新商品
  static Future<Result<void, String>> createProduct({
    required final Product product,
    required final File image,
  }) async {
    try {
      // 獲取當前用戶 ID
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      // 先上傳圖片
      final String imagePath = await _uploadProductImage(store, image);

      // 準備商品資料
      final productData = product.toJson();
      productData['store_id'] = store.id; // 確保 store_id 正確
      productData['image_path'] = imagePath; // 更新圖片路徑
      productData.remove('id'); // 移除 id，讓資料庫自動生成
      productData.remove('product_sizes'); // 移除 sizes，稍後分開處理

      final response = await _supabase
          .from(_productsTable)
          .insert(productData)
          .select('id')
          .single();

      final productId = response['id'];
      final sizes = product.sizes ?? [];

      if (sizes.isNotEmpty) {
        final sizesData = sizes.map((final size) {
          return {
            'product_id': productId,
            'name': size.name,
            ...size.measurements.toJson(),
          };
        }).toList();

        await _supabase.from(_productSizesTable).insert(sizesData);
      }

      // 4. 取得完整資料並更新本地快取
      final newProductJson = await _supabase
          .from(_productsTable)
          .select('*, product_sizes(*)')
          .eq('id', productId)
          .single();

      final newProduct = Product.fromJson(Map<String, dynamic>.from(newProductJson));

      CachedQuery.instance.updateQuery(
        key: ['products', store.id],
        updateFn: (final dynamic oldList) {
          if (oldList == null) return [newProduct];
          return [newProduct, ...(oldList as List<Product>)];
        },
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品創建失敗', e);
      return const Err('新增商品失敗，請稍後再試');
    }
  }

  /// 更新商品
  static Future<Result<void, String>> updateProduct({
    required final Product original,
    required final Product target,
    final File? newImage,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      // 1. 取得變更的欄位 (Dirty Checking)
      final updateData = original.getDirtyFields(target);
      final sizeChanges = original.sizes.getDirtyFields(target.sizes);

      // 如果完全沒有變動，直接回傳
      if (updateData.isEmpty && newImage == null && !sizeChanges.hasChanges) {
        return const Ok(null);
      }

      // 如果有新圖片，則處理圖片上傳與舊圖刪除
      if (newImage != null) {
        await _deleteProductImage(original.imagePath);
        updateData['image_path'] = await _uploadProductImage(store, newImage);
      }

      // 如果有一般欄位需要更新
      if (updateData.isNotEmpty) {
        await _supabase.from(_productsTable).update(updateData).eq('id', original.id!);
      }

      // 2. 處理尺寸變更
      if (sizeChanges.hasChanges) {
        // A. 刪除
        for (final id in sizeChanges.toDeleteIds) {
          await _supabase.from(_productSizesTable).delete().eq('id', id);
        }

        // B. 新增
        for (final newSize in sizeChanges.toAdd) {
          await _supabase.from(_productSizesTable).insert({
            'product_id': original.id,
            'name': newSize.name,
            ...newSize.measurements.toJson(),
          });
        }

        // C. 更新
        for (final updateEntry in sizeChanges.toUpdate) {
          final id = updateEntry['id'];
          final dirtyFields = updateEntry['dirtyFields'];
          await _supabase.from(_productSizesTable).update(dirtyFields).eq('id', id);
        }
      }

      // 3. 取得完整資料並更新本地快取
      final updatedProductJson = await _supabase
          .from(_productsTable)
          .select('*, product_sizes(*)')
          .eq('id', original.id!)
          .single();

      final updatedProduct = Product.fromJson(
        Map<String, dynamic>.from(updatedProductJson),
      );

      CachedQuery.instance.updateQuery(
        key: ['products', store.id],
        updateFn: (final dynamic oldList) {
          if (oldList == null) return [updatedProduct];
          return (oldList as List<Product>)
              .map((final p) => p.id == updatedProduct.id ? updatedProduct : p)
              .toList();
        },
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品更新失敗', e);
      return const Err('更新商品失敗，請稍後再試');
    }
  }

  /// 刪除商品
  static Future<Result<void, String>> deleteProduct(final Product product) async {
    try {
      final store = _supabase.auth.currentUser;
      // 刪除圖片（Supabase Storage 和本地）
      if (product.imagePath.isNotEmpty) {
        await _deleteProductImage(product.imagePath);
      }

      // 刪除商品資料
      await _supabase.from(_productsTable).delete().eq('id', product.id!);

      // 更新本地快取
      if (store != null) {
        CachedQuery.instance.updateQuery(
          key: ['products', store.id],
          updateFn: (final dynamic oldList) {
            if (oldList == null) return [];
            return (oldList as List<Product>)
                .where((final p) => p.id != product.id)
                .toList();
          },
        );
      }

      return const Ok(null);
    } catch (e) {
      AppLogger.error('商品刪除失敗', e);
      return const Err('刪除商品失敗，請稍後再試');
    }
  }

  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String> _uploadProductImage(final store, final File image) async {
    // 使用圖片本身的檔案名稱
    final imageName = p.basename(image.path);
    final productImagePath = '${store.id}/products/$imageName';

    final bytes = await image.readAsBytes();
    final mimeType = lookupMimeType(image.path);

    // 上傳到 Supabase Storage
    await _supabase.storage
        .from(_productImagesBucket)
        .uploadBinary(
          productImagePath,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
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
  static List<Product> sortProducts(
    final List<Product> products,
    final String sortBy,
    final bool ascending,
  ) {
    final sortedProducts = products;

    sortedProducts.sort((final a, final b) {
      int comparison;

      switch (sortBy) {
        case 'name':
          comparison = -a.name.compareTo(b.name);
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
        case 'tryon_count':
          comparison = (a.tryonCount ?? 0).compareTo(b.tryonCount ?? 0);
          break;
        case 'purchase_click_count':
          comparison = (a.purchaseClickCount ?? 0).compareTo(b.purchaseClickCount ?? 0);
          break;
        default:
          comparison = 0;
      }

      return ascending ? comparison : -comparison;
    });

    return sortedProducts;
  }
}
