import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/data/models/product_model.dart';
import 'store_info_service.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';
  static const _productImagesBucket = 'product-images';

  /// 創建新商品
  static Future<bool> createProduct({
    required String name,
    required String type,
    required double price,
    required String purchaseLink,
    required File imageFile,
  }) async {
    try {
      // 獲取當前店家資料
      final storeData = await StoreService.getStore();
      if (storeData == null) return false;
      
      // 如果有圖片，先上傳圖片
      String imageUrl = await uploadProductImage(imageFile) ?? '';

      // 創建商品資料
      final product = Product(
        storeId: storeData.id,
        name: name,
        type: type,
        price: price,
        purchaseLink: purchaseLink,
        imageUrl: imageUrl,
      );

      // 插入到資料庫
      await _supabase
          .from(_productsTable)
          .insert(product.toJson());

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 更新商品
  static Future<bool> updateProduct({
    required String productId,
    required String name,
    required String type,
    required double price,
    required String purchaseLink,
    required String currentImageUrl,
    File? newImageFile
  }) async {
    try {
      String? imageUrl = currentImageUrl;
      
      // 如果有新圖片，上傳新圖片並刪除舊圖片
      if (newImageFile != null) {
        // 上傳新圖片
        final newImageUrl = await uploadProductImage(newImageFile);
        
        // 如果新圖片上傳成功，刪除舊圖片
        if (newImageUrl != null && currentImageUrl.isNotEmpty) {
          await deleteProductImage(currentImageUrl);
        }
        
        imageUrl = newImageUrl;
      }

      final updateData = {
        'name': name,
        'type': type,
        'price': price,
        'image_url': imageUrl,
        'purchase_link': purchaseLink,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from(_productsTable)
          .update(updateData)
          .eq('id', productId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 刪除商品
  static Future<bool> deleteProduct(String productId) async {
    try {
      // 先獲取商品資料以取得圖片 URL
      final response = await _supabase
          .from(_productsTable)
          .select('image_url')
          .eq('id', productId)
          .single();
      
      final imageUrl = response['image_url'] as String?;
      
      // 如果有圖片，從 Storage 中刪除
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteProductImage(imageUrl);
      }
      
      // 刪除商品資料
      await _supabase
          .from(_productsTable)
          .delete()
          .eq('id', productId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 獲取店家的所有商品
  static Future<List<Product>> getStoreProducts() async {
    try {
      final storeData = await StoreService.getStore();
      if (storeData == null) return [];

      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('store_id', storeData.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 上傳商品圖片
  static Future<String?> uploadProductImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 生成唯一的檔案名稱
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$userId/product_$timestamp.jpg';
      
      final bytes = await imageFile.readAsBytes();

      // 上傳到 Supabase Storage
      await _supabase.storage.from(_productImagesBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // 獲取公開 URL
      final imageUrl = _supabase.storage
          .from(_productImagesBucket)
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      return null;
    }
  }

  /// 刪除商品圖片
  static Future<void> deleteProductImage(String imageUrl) async {
    if (imageUrl.isEmpty) return;
    
    try {
      // 從 URL 中提取檔案路徑
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // 找出 product-images bucket 後的路徑
      final bucketIndex = pathSegments.indexOf(_productImagesBucket);
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        // 刪除 Storage 中的圖片
        await _supabase.storage
            .from(_productImagesBucket)
            .remove([filePath]);
      }
    } catch (e) {
      // 圖片刪除失敗不會拋出錯誤
      print('Error deleting product image: $e');
    }
  }
}