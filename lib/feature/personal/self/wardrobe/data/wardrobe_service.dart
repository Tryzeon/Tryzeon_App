import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _wardrobeTable = 'wardrobe_items';
  static const _bucket = 'wardrobe';
  
  static const _cacheKey = 'wardrobe_items_cache';

  static Future<List<WardrobeItem>> getWardrobeItems({bool forceRefresh = false}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 如果不是強制刷新，先嘗試從快取讀取
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final items = cachedData
              .map((json) => WardrobeItem(
                    id: json['id'],
                    path: json['image_path'],
                    category: json['category'],
                    imageUrl: json['image_path'],
                  ))
              .toList();
          return items;
        }
      }
      
      // 從資料庫獲取資料
      final response = await _supabase
          .from(_wardrobeTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      await CacheService.saveList(_cacheKey, response);

      final items = (response as List)
          .map((json) => WardrobeItem(
                id: json['id'],
                path: json['image_path'],
                category: json['category'],
                imageUrl: json['image_path'],
              ))
          .toList();

      return items;
    } catch (e) {
      return [];
    }
  }

  static Future<bool> uploadWardrobeItem(File imageFile, String category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final categoryCode = getWardrobeTypesEnglishCode(category);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$userId/$categoryCode/$timestamp.jpg';

    try {
      // 1. 上傳圖片到 Supabase Storage
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from(_bucket).uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      // 2. 保存到本地緩存
      await CacheService.saveFile(imageFile, storagePath);

      // 3. 新增 DB 記錄
      await _supabase.from(_wardrobeTable).insert({
        'user_id': userId,
        'category': category,
        'image_path': storagePath,
      });

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> deleteWardrobeItem(WardrobeItem item) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || item.id == null) return;

    try {
      // 1. 刪除 DB 記錄
      await _supabase
          .from(_wardrobeTable)
          .delete()
          .eq('id', item.id!);

      // 2. 刪除 Supabase Storage 中的圖片
      await _supabase.storage.from(_bucket).remove([item.imageUrl]);

      // 3. 刪除本地快取的圖片
      await CacheService.deleteFile(item.imageUrl);

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);
    } catch (e) {
      // 圖片刪除失敗不會拋出錯誤
    }
  }

  static Future<File?> getWardrobeImage(String storagePath) async {

    try {
      // 1. 先檢查本地是否有該圖片
      final localFile = await CacheService.getFile(storagePath);
      if (localFile != null && await localFile.exists()) {
        return localFile;
      }

      // 2. 本地沒有，從 Supabase 下載
      final bytes = await _supabase.storage.from(_bucket).download(storagePath);

      final imageName = storagePath.split('/').last;

      // 創建臨時文件並保存到本地緩存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_wardrobe_$imageName');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await CacheService.saveFile(tempFile, storagePath);
      await tempFile.delete();

      return savedFile;
    } catch (e) {
      return null;
    }
  }

  static List<String> getWardrobeTypesList() {
    return WardrobeType.all.map((t) => t.zh).toList();
  }

  static String getWardrobeTypesEnglishCode(String nameZh) {
    final type = WardrobeType.all.where((t) => t.zh == nameZh).firstOrNull;
    return type?.en ?? nameZh;
  }
}

class WardrobeType {
  final String zh;
  final String en;

  const WardrobeType({
    required this.zh,
    required this.en,
  });

  static const List<WardrobeType> all = [
    WardrobeType(zh: '上衣', en: 'top'),
    WardrobeType(zh: '褲子', en: 'pants'),
    WardrobeType(zh: '裙子', en: 'skirt'),
    WardrobeType(zh: '外套', en: 'jacket'),
    WardrobeType(zh: '鞋子', en: 'shoes'),
    WardrobeType(zh: '配件', en: 'accessories'),
    WardrobeType(zh: '其他', en: 'others'),
  ];
}

class WardrobeItem {
  final String? id;
  final String path;
  final String category;
  final String imageUrl;

  WardrobeItem({
    this.id,
    required this.path,
    required this.category,
    required this.imageUrl,
  });
}
