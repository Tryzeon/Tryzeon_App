import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
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
  static Future<void> saveList(
    final String cacheKey,
    final List<dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      AppLogger.error('Failed to save list cache for $cacheKey', e);
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
      return null;
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
    }
  }

  /// 保存檔案到指定的緩存路徑
  ///
  /// [bytes] 要保存的檔案數據
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 保存後的檔案
  static Future<File> saveImage(
    final Uint8List bytes,
    final String filePath,
  ) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();

      // 分離目錄路徑和檔名
      final lastSlashIndex = filePath.lastIndexOf('/');
      final dirPath = filePath.substring(0, lastSlashIndex);

      final targetDir = Directory('${baseDir.path}/$dirPath');

      // 創建目錄（如果不存在）
      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }

      // 保存檔案
      final targetPath = '${baseDir.path}/$filePath';
      final file = File(targetPath);
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      AppLogger.error('Failed to save image to $filePath', e);
      rethrow;
    }
  }

  /// 獲取指定路徑的檔案
  ///
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 找到的檔案，如果不存在則返回 null
  static Future<File?> getImage(final String filePath) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final file = File('${baseDir.path}/$filePath');

      if (await file.exists()) {
        return file;
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to get image from $filePath', e);
      return null;
    }
  }

  /// 獲取指定路徑下所有符合模式的檔案
  ///
  /// [relativePath] 相對於應用目錄的路徑
  /// [filePattern] 要查找的檔案模式（選填）
  ///
  /// Returns 找到的檔案列表
  static Future<List<File>> getImages({
    required final String relativePath,
    final String? filePattern,
  }) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${baseDir.path}/$relativePath');

      if (!targetDir.existsSync()) return [];

      final files = targetDir.listSync().whereType<File>();

      if (filePattern != null) {
        return files.where((final f) => f.path.contains(filePattern)).toList();
      }

      return files.toList();
    } catch (e) {
      AppLogger.error('Failed to get images from $relativePath', e);
      return [];
    }
  }

  /// 刪除指定的單個檔案
  ///
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  static Future<void> deleteImage(final String filePath) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final file = File('${baseDir.path}/$filePath');

      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.error('Failed to delete image at $filePath', e);
    }
  }

  /// 刪除指定路徑下的所有檔案
  ///
  /// [relativePath] 相對於應用目錄的路徑（例如：'userId/avatar'）
  static Future<void> deleteImages({required final String relativePath}) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${baseDir.path}/$relativePath');

      if (await targetDir.exists()) {
        final files = targetDir.listSync().whereType<File>();
        for (final file in files) {
          await file.delete();
        }
      }
    } catch (e) {
      AppLogger.error('Failed to delete images at $relativePath', e);
    }
  }

  /// 刪除指定的資料夾及其所有內容
  ///
  /// [relativePath] 相對於應用目錄的資料夾路徑（例如：'userId'）
  static Future<void> deleteFolder(final String relativePath) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final directory = Directory('${baseDir.path}/$relativePath');

      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (e) {
      AppLogger.error('Failed to delete folder at $relativePath', e);
    }
  }
}
