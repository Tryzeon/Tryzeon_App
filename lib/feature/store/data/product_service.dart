import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/models/product_model.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class ProductService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';
  static const _productImagesBucket = 'store';

  /// 獲取店家的所有商品
  static Future<List<Product>> getStoreProducts() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from(_productsTable)
          .select()
          .eq('store_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 獲取商品圖片（優先從本地獲取，本地沒有才從後端拿）
  static Future<File?> getProductImage(String filePath) async {
    if (filePath.isEmpty) return null;

    try {
      // 1. 先檢查本地是否有該圖片
      final localFile = await FileCacheService.getFile(filePath);
      if (localFile != null && await localFile.exists()) {
        return localFile;
      }

      // 2. 本地沒有，從 Supabase 下載
      final bytes = await _supabase.storage.from(_productImagesBucket).download(filePath);

      // 從 filePath 提取檔名
      final imageName = filePath.split('/').last;

      // 創建臨時文件並保存到本地緩存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_product_$imageName');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await FileCacheService.saveFile(tempFile, filePath);
      await tempFile.delete(); // 刪除臨時文件

      return savedFile;
    } catch (e) {
      return null;
    }
  }
  
  /// 創建新商品
  static Future<bool> createProduct({
    required String name,
    required String type,
    required double price,
    required String purchaseLink,
    required File imageFile,
  }) async {
    try {
      // 獲取當前用戶 ID
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // 如果有圖片，先上傳圖片
      String filePath = await _uploadProductImage(imageFile) ?? '';

      // 創建商品資料
      final product = Product(
        storeId: userId,
        name: name,
        type: type,
        price: price,
        purchaseLink: purchaseLink,
        imagePath: filePath,
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
        'type': type,
        'price': price,
        'image_path': filePath,
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
  static Future<bool> deleteProduct(Product product) async {
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

      return true;
    } catch (e) {
      // Error during deletion
      return false;
    }
  }


  /// 上傳商品圖片（先上傳到後端，成功後才保存到本地）
  static Future<String?> _uploadProductImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 生成唯一的檔案名稱
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageName = '$timestamp.jpg';
      final filePath = '$userId/products/$imageName';

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
      await FileCacheService.saveFile(imageFile, filePath);

      // 返回檔案路徑
      return filePath;
    } catch (e) {
      rethrow;
    }
  }

  /// 刪除商品圖片（Supabase 和本地）
  static Future<void> _deleteProductImage(String filePath) async {
    if (filePath.isEmpty) return;

    try {
      // 1. 刪除 Supabase Storage 中的圖片
      await _supabase.storage
          .from(_productImagesBucket)
          .remove([filePath]);

      // 2. 刪除本地緩存的圖片
      await FileCacheService.deleteFile(filePath);
    } catch (e) {
      // 圖片刪除失敗不會拋出錯誤
    }
  }
}