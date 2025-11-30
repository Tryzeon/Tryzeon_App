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

  static Future<Result<List<WardrobeItem>>> getWardrobeItem({
    final bool forceRefresh = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 如果不是強制刷新，先嘗試從快取讀取
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final wardrobeItem = cachedData
              .map((final json) => WardrobeItem.fromJson(json))
              .toList();
          return Result.success(data: wardrobeItem);
        }
      }

      // 從資料庫獲取資料
      final response = await _supabase
          .from(_wardrobeTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      await CacheService.saveList(_cacheKey, response);

      final wardrobeItem = (response as List)
          .map((final json) => WardrobeItem.fromJson(json))
          .toList();

      return Result.success(data: wardrobeItem);
    } catch (e) {
      return Result.failure('衣櫃列表獲取失敗', error: e);
    }
  }

  static Future<Result<void>> uploadWardrobeItem(
    final File imageFile,
    final String category, {
    final List<String> tags = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return Result.failure('使用者獲取失敗');
      }

      final categoryCode = getWardrobeTypesEnglishCode(category);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$userId/$categoryCode/$timestamp.jpg';

      // 1. 上傳圖片到 Supabase Storage
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg'
            ),
          );

      // 2. 保存到本地緩存
      await CacheService.saveImage(bytes, storagePath);

      // 3. 新增 DB 記錄
      await _supabase.from(_wardrobeTable).insert({
        'user_id': userId,
        'category': category,
        'image_path': storagePath,
        'tags': tags,
      });

      // 4. 清除快取以確保下次獲取最新資料
      await CacheService.clearCache(_cacheKey);

      return Result.success();
    } catch (e) {
      return Result.failure('衣物上傳失敗', error: e);
    }
  }

  static Future<Result<void>> deleteWardrobeItem(
    final WardrobeItem item,
  ) async {
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

  static Future<Result<File>> loadWardrobeItemImage(
    final String storagePath,
  ) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedFile = await CacheService.getImage(storagePath);
      if (cachedFile != null && await cachedFile.exists()) {
        return Result.success(data: cachedFile);
      }

      // 2. 本地沒有，從 Supabase 下載並保存到本地緩存
      final bytes = await _supabase.storage.from(_bucket).download(storagePath);
      final savedFile = await CacheService.saveImage(bytes, storagePath);

      return Result.success(data: savedFile);
    } catch (e) {
      return Result.failure('衣櫃圖片載入失敗', error: e);
    }
  }

  static List<String> getWardrobeTypesList() {
    return WardrobeItemType.all.map((final t) => t.zh).toList();
  }

  static String getWardrobeTypesEnglishCode(final String nameZh) {
    final type = WardrobeItemType.all
        .where((final t) => t.zh == nameZh)
        .firstOrNull;
    return type?.en ?? nameZh;
  }
}
