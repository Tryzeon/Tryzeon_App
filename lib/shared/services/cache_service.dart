import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

class CacheService {
  /// 儲存資料到 SharedPreferences（自動進行 JSON 編碼）
  ///
  /// [cacheKey] 緩存的鍵
  /// [data] 要緩存的資料
  static Future<void> saveJSON(
    final String cacheKey,
    final Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      AppLogger.error('Failed to save cache for $cacheKey', e);
    }
  }

  /// 從 SharedPreferences 載入資料（自動進行 JSON 解碼）
  ///
  /// [cacheKey] 緩存的鍵
  ///
  /// Returns 緩存的資料，如果不存在或解碼失敗則返回 null
  static Future<Map<String, dynamic>?> loadJSON(final String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('Failed to load cache for $cacheKey', e);
      return null;
    }
  }

  /// 儲存 List 到 SharedPreferences（自動進行 JSON 編碼）
  ///
  /// [cacheKey] 緩存的鍵
  /// [data] 要緩存的列表
  static Future<void> saveList(final String cacheKey, final List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      AppLogger.error('Failed to save list cache for $cacheKey', e);
      rethrow;
    }
  }

  /// 從 SharedPreferences 載入 List（自動進行 JSON 解碼）
  ///
  /// [cacheKey] 緩存的鍵
  ///
  /// Returns 緩存的列表，如果不存在或解碼失敗則返回 null
  static Future<List<dynamic>?> loadList(final String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      AppLogger.error('Failed to load list cache for $cacheKey', e);
      rethrow;
    }
  }

  /// 清除指定的緩存
  ///
  /// [cacheKey] 緩存的鍵
  static Future<void> clearCache(final String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
    } catch (e) {
      AppLogger.error('Failed to clear cache for $cacheKey', e);
      rethrow;
    }
  }

  /// 保存檔案到緩存
  ///
  /// [bytes] 要保存的檔案數據
  /// [filePath] 檔案路徑，將作為緩存的 key
  ///
  /// Returns 保存後的檔案
  static Future<File> saveImage(final Uint8List bytes, final String filePath) async {
    try {
      return await DefaultCacheManager().putFile(filePath, bytes, key: filePath);
    } catch (e) {
      AppLogger.error('Failed to save image to $filePath', e);
      rethrow;
    }
  }

  /// 獲取緩存的檔案
  ///
  /// [filePath] 檔案路徑，作為緩存的 key
  /// [downloadUrl] 如果提供，當緩存不存在時會嘗試從此 URL 下載
  ///
  /// Returns 找到的檔案，如果不存在則返回 null
  static Future<File?> getImage(
    final String filePath, {
    final String? downloadUrl,
  }) async {
    try {
      if (downloadUrl != null) {
        return await DefaultCacheManager().getSingleFile(downloadUrl, key: filePath);
      }

      final fileInfo = await DefaultCacheManager().getFileFromCache(filePath);
      return fileInfo?.file;
    } catch (e) {
      AppLogger.error('Failed to get image from $filePath', e);
      rethrow;
    }
  }

  /// 刪除指定的緩存檔案
  ///
  /// [filePath] 檔案路徑，作為緩存的 key
  static Future<void> deleteImage(final String filePath) async {
    try {
      await DefaultCacheManager().removeFile(filePath);
    } catch (e) {
      AppLogger.error('Failed to delete image at $filePath', e);
      rethrow;
    }
  }

  /// 清空所有緩存
  static Future<void> emptyCache() async {
    try {
      await DefaultCacheManager().emptyCache();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      AppLogger.error('Failed to empty cache', e);
      rethrow;
    }
  }
}
