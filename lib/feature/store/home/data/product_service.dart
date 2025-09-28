import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_model.dart';
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
    File? imageFile,
  }) async {
    try {
      // 獲取當前店家資料
      final storeData = await StoreService.getStore();
      if (storeData == null) return false;

      String? imageUrl;
      
      // 如果有圖片，先上傳圖片
      if (imageFile != null) {
        imageUrl = await uploadProductImage(imageFile);
      }

      // 創建商品資料
      final product = Product(
        storeId: storeData.id,
        name: name,
        type: type,
        price: price,
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
      print('Error uploading product image: $e');
      return null;
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
}