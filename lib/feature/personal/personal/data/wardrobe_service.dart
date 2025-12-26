import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

import 'wardrobe_item_model.dart';

class WardrobeService {
  static final _supabase = Supabase.instance.client;
  static const _wardrobeTable = 'wardrobe_items';
  static const _bucket = 'wardrobe';

  static Query<List<WardrobeItem>> wardrobeItemsQuery() {
    final user = _supabase.auth.currentUser;
    final id = user?.id;

    return Query<List<WardrobeItem>>(
      key: ['wardrobe_items', id],
      queryFn: fetchWardrobeItems,
      config: QueryConfig(
        storageDeserializer: (final dynamic json) {
          if (json == null) return [];
          return (json as List).map((final e) => WardrobeItem.fromJson(e)).toList();
        },
      ),
    );
  }

  static Future<List<WardrobeItem>> fetchWardrobeItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw '無法獲取使用者資訊，請重新登入';
    }

    final response = await _supabase
        .from(_wardrobeTable)
        .select('id, image_path, category, tags')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((final json) => WardrobeItem.fromJson(json))
        .toList()
        .cast<WardrobeItem>();
  }

  static Future<Result<void, String>> createWardrobeItem(
    final File image,
    final String category, {
    final List<String> tags = const [],
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      final categoryCode = getWardrobeTypesEnglishCode(category);
      final imagePath = await _uploadWardrobeItemImage(user, image, categoryCode);

      // 3. 新增 DB 記錄並回傳最新資料
      final response = await _supabase
          .from(_wardrobeTable)
          .insert({
            'user_id': user.id,
            'category': category,
            'image_path': imagePath,
            'tags': tags,
          })
          .select()
          .single();

      // 4. 更新本地快取
      final newItem = WardrobeItem.fromJson(response);
      CachedQuery.instance.updateQuery(
        key: ['wardrobe_items', user.id],
        updateFn: (final dynamic oldList) {
          if (oldList == null) return [newItem];
          return [newItem, ...(oldList as List<WardrobeItem>)];
        },
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('衣物上傳失敗', e);
      return const Err('上傳衣物失敗，請稍後再試');
    }
  }

  static Future<Result<void, String>> deleteWardrobeItem(final WardrobeItem item) async {
    try {
      final user = _supabase.auth.currentUser;
      // 1. 刪除 DB 記錄
      await _supabase.from(_wardrobeTable).delete().eq('id', item.id!);

      // 2. 刪除 Supabase Storage 中的圖片
      await _supabase.storage.from(_bucket).remove([item.imagePath]);

      // 3. 刪除本地快取的圖片
      await CacheService.deleteImage(item.imagePath);

      // 4. 更新本地快取
      if (user != null) {
        CachedQuery.instance.updateQuery(
          key: ['wardrobe_items', user.id],
          updateFn: (final dynamic oldList) {
            if (oldList == null) return [];
            return (oldList as List<WardrobeItem>)
                .where((final i) => i.id != item.id)
                .toList();
          },
        );
      }

      return const Ok(null);
    } catch (e) {
      AppLogger.error('衣物刪除失敗', e);
      return const Err('刪除衣物失敗，請稍後再試');
    }
  }

  static Future<Result<File, String>> getWardrobeItemImage(final String imagePath) async {
    try {
      // 1. 先檢查本地是否有該圖片
      final cachedImage = await CacheService.getImage(imagePath);
      if (cachedImage != null) {
        return Ok(cachedImage);
      }

      // 2. 本地沒有，從 Supabase 取得 Signed URL 下載
      final url = await _supabase.storage.from(_bucket).createSignedUrl(imagePath, 60);

      final image = await CacheService.getImage(imagePath, downloadUrl: url);

      if (image == null) return const Err('無法載入衣物圖片，請稍後再試');
      return Ok(image);
    } catch (e) {
      AppLogger.error('衣櫃圖片載入失敗', e);
      return const Err('無法載入衣物圖片，請稍後再試');
    }
  }

  /// 上傳衣物圖片（先上傳到後端，成功後才保存到本地）
  static Future<String> _uploadWardrobeItemImage(
    final User user,
    final File image,
    final String categoryCode,
  ) async {
    // 生成唯一的檔案名稱
    final imageName = p.basename(image.path);
    final imagePath = '${user.id}/$categoryCode/$imageName';

    final bytes = await image.readAsBytes();
    final mimeType = lookupMimeType(image.path);

    // 上傳到 Supabase Storage
    await _supabase.storage
        .from(_bucket)
        .uploadBinary(imagePath, bytes, fileOptions: FileOptions(contentType: mimeType));

    // 保存到本地緩存
    await CacheService.saveImage(bytes, imagePath);

    // 返回檔案路徑
    return imagePath;
  }

  static List<String> getWardrobeTypesList() {
    return WardrobeItemType.all.map((final t) => t.zh).toList();
  }

  static String getWardrobeTypesEnglishCode(final String nameZh) {
    final type = WardrobeItemType.all.where((final t) => t.zh == nameZh).firstOrNull;
    return type?.en ?? nameZh;
  }
}
