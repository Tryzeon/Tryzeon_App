import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:stash/stash_api.dart';
import 'package:stash_shared_preferences/stash_shared_preferences.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

class CacheService {
  static Cache? _cache;

  /// 初始化並獲取 Cache 實例
  static Future<Cache> get _getCache async {
    if (_cache != null) return _cache!;

    // 建立基於 SharedPreferences 的 CacheStore
    final store = await newSharedPreferencesCacheStore();

    // 建立 Cache，預設過期時間為 7 天
    _cache = await store.cache(
      name: 'app_general_cache',
      expiryPolicy: const CreatedExpiryPolicy(Duration(days: 7)),
    );

    return _cache!;
  }

  /// 儲存資料到緩存
  ///
  /// [key] 緩存鍵
  /// [value] 要儲存的資料 (支援 Map, List, String, int, bool 等基本型別)
  static Future<void> saveToCache(final String key, final dynamic value) async {
    try {
      final cache = await _getCache;
      await cache.put(key, value);
    } catch (e) {
      AppLogger.error('Failed to save to cache: $key', e);
    }
  }

  /// 從緩存讀取資料
  ///
  /// [key] 緩存鍵
  ///
  /// Returns 緩存的資料，如果不存在或已過期則返回 null
  static Future<dynamic> loadFromCache(final String key) async {
    try {
      final cache = await _getCache;
      return await cache.get(key);
    } catch (e) {
      AppLogger.error('Failed to load from cache: $key', e);
      return null;
    }
  }

  /// 清除指定的緩存
  ///
  /// [key] 緩存的鍵
  static Future<void> deleteCache(final String key) async {
    try {
      final cache = await _getCache;
      await cache.remove(key);
    } catch (e) {
      AppLogger.error('Failed to clear cache for $key', e);
    }
  }

  /// 保存檔案到緩存 (圖片專用)
  static Future<File> saveImage(final Uint8List bytes, final String filePath) async {
    try {
      return await fcm.DefaultCacheManager().putFile(filePath, bytes, key: filePath);
    } catch (e) {
      AppLogger.error('Failed to save image to $filePath', e);
      rethrow;
    }
  }

  /// 獲取緩存的檔案 (圖片專用)
  static Future<File?> getImage(
    final String filePath, {
    final String? downloadUrl,
  }) async {
    try {
      if (downloadUrl != null) {
        return await fcm.DefaultCacheManager().getSingleFile(downloadUrl, key: filePath);
      }

      final fileInfo = await fcm.DefaultCacheManager().getFileFromCache(filePath);
      return fileInfo?.file;
    } catch (e) {
      AppLogger.error('Failed to get image from $filePath', e);
      rethrow;
    }
  }

  /// 刪除指定的緩存檔案 (圖片專用)
  static Future<void> deleteImage(final String filePath) async {
    try {
      await fcm.DefaultCacheManager().removeFile(filePath);
    } catch (e) {
      AppLogger.error('Failed to delete image at $filePath', e);
      rethrow;
    }
  }

  /// 清空所有緩存 (包含圖片與資料)
  static Future<void> clearCache() async {
    try {
      final cache = await _getCache;
      await cache.clear();

      await fcm.DefaultCacheManager().emptyCache();
    } catch (e) {
      AppLogger.error('Failed to empty cache', e);
    }
  }
}
