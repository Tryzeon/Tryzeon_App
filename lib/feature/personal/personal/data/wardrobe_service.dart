import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

import 'wardrobe_item_model.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _wardrobeTable = 'wardrobe_items';
  static const _bucket = 'wardrobe';

  static const _cacheKey = 'wardrobe_items_cache';

  static Future<Result<List<WardrobeItem>>> getWardrobeItems({
    final bool forceRefresh = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 如果不是強制刷新，先嘗試從快取讀取
      if (!forceRefresh) {
        final cachedData = await CacheService.loadFromCache(_cacheKey);
        if (cachedData != null) {
          final cachedWardrobeItems = cachedData
              .map((final json) => WardrobeItem.fromJson(Map<String, dynamic>.from(json as Map)))
              .toList()
              .cast<WardrobeItem>();
          return Result.success(data: cachedWardrobeItems);
        }
      }

      // 從資料庫獲取資料
      final response = await _supabase
          .from(_wardrobeTable)
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      await CacheService.saveToCache(_cacheKey, response);

      final wardrobeItems = (response as List)
          .map((final json) => WardrobeItem.fromJson(json))
          .toList()
          .cast<WardrobeItem>();

      return Result.success(data: wardrobeItems);
    } catch (e) {
      return Result.failure('衣櫃列表獲取失敗', error: e);
    }
  }

  static Future<Result<void>> uploadWardrobeItem(
    final File image,
    final String category, {
    final List<String> tags = const [],
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者獲取失敗');
      }

      final categoryCode = getWardrobeTypesEnglishCode(category);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath = '${user.id}/$categoryCode/$timestamp.jpg';

      // 1. 上傳圖片到 Supabase Storage
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            imagePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // 2. 保存到本地緩存
      await CacheService.saveImage(bytes, imagePath);

      // 3. 新增 DB 記錄
      await _supabase.from(_wardrobeTable).insert({
        'user_id': user.id,
        'category': category,
        'image_path': imagePath,
        'tags': tags,
      });

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('衣物上傳失敗', error: e);
    }
  }

  static Future<Result<void>> deleteWardrobeItem(final WardrobeItem item) async {
    try {
      // 1. 刪除 DB 記錄
      await _supabase.from(_wardrobeTable).delete().eq('id', item.id!);

      // 2. 刪除 Supabase Storage 中的圖片
      await _supabase.storage.from(_bucket).remove([item.imagePath]);

      // 3. 刪除本地快取的圖片
      await CacheService.deleteImage(item.imagePath);

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('衣物刪除失敗', error: e);
    }
  }

  static Future<Result<File>> loadWardrobeItemImage(final String imagePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedImage = await CacheService.getImage(imagePath);
      if (cachedImage != null) {
        return Result.success(data: cachedImage);
      }

      // 2. 本地沒有，從 Supabase 取得 Signed URL 下載
      final url = await _supabase.storage.from(_bucket).createSignedUrl(imagePath, 60);

      final image = await CacheService.getImage(imagePath, downloadUrl: url);

      return Result.success(data: image);
    } catch (e) {
      return Result.failure('衣櫃圖片載入失敗', error: e);
    }
  }

  static List<String> getWardrobeTypesList() {
    return WardrobeItemType.all.map((final t) => t.zh).toList();
  }

  static String getWardrobeTypesEnglishCode(final String nameZh) {
    final type = WardrobeItemType.all.where((final t) => t.zh == nameZh).firstOrNull;
    return type?.en ?? nameZh;
  }
}
