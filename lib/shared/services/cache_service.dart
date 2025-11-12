import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  /// 儲存資料到 SharedPreferences（自動進行 JSON 編碼）
  ///
  /// [cacheKey] 緩存的鍵
  /// [data] 要緩存的資料
  static Future<void> saveJSON(String cacheKey, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      // 忽略快取錯誤
    }
  }

  /// 從 SharedPreferences 載入資料（自動進行 JSON 解碼）
  ///
  /// [cacheKey] 緩存的鍵
  ///
  /// Returns 緩存的資料，如果不存在或解碼失敗則返回 null
  static Future<Map<String, dynamic>?> loadJSON(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // 快取錯誤或解碼失敗，返回 null
      return null;
    }
  }

  /// 儲存 List 到 SharedPreferences（自動進行 JSON 編碼）
  ///
  /// [cacheKey] 緩存的鍵
  /// [data] 要緩存的列表
  static Future<void> saveList(String cacheKey, List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(data);
      await prefs.setString(cacheKey, jsonString);
    } catch (e) {
      // 忽略快取錯誤
    }
  }

  /// 從 SharedPreferences 載入 List（自動進行 JSON 解碼）
  ///
  /// [cacheKey] 緩存的鍵
  ///
  /// Returns 緩存的列表，如果不存在或解碼失敗則返回 null
  static Future<List<dynamic>?> loadList(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(cacheKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      // 快取錯誤或解碼失敗，返回 null
      return null;
    }
  }

  /// 清除指定的緩存
  ///
  /// [cacheKey] 緩存的鍵
  static Future<void> clearCache(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
    } catch (e) {
      // 忽略錯誤
    }
  }

  /// 保存檔案到指定的緩存路徑
  ///
  /// [sourceFile] 要保存的源文件
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 保存後的檔案
  static Future<File> saveImage(File sourceFile, String filePath) async {
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
    final savedFile = await sourceFile.copy(targetPath);
    print("Cache file saved to $targetPath");
    return savedFile;
  }

  /// 獲取指定路徑的檔案
  ///
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 找到的檔案，如果不存在則返回 null
  static Future<File?> getImage(String filePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final file = File('${baseDir.path}/$filePath');

    if (await file.exists()) {
      return file;
    }

    return null;
  }

  /// 獲取指定路徑下所有符合模式的檔案
  ///
  /// [relativePath] 相對於應用目錄的路徑
  /// [filePattern] 要查找的檔案模式（選填）
  ///
  /// Returns 找到的檔案列表
  static Future<List<File>> getImages({
    required String relativePath,
    String? filePattern,
  }) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${baseDir.path}/$relativePath');

    if (!targetDir.existsSync()) return [];

    final files = targetDir.listSync().whereType<File>();

    if (filePattern != null) {
      return files.where((f) => f.path.contains(filePattern)).toList();
    }

    return files.toList();
  }

  /// 刪除指定的單個檔案
  ///
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  static Future<void> deleteImage(String filePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final file = File('${baseDir.path}/$filePath');

    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 刪除指定路徑下的所有檔案
  ///
  /// [relativePath] 相對於應用目錄的路徑（例如：'userId/avatar'）
  static Future<void> deleteImages({required String relativePath}) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${baseDir.path}/$relativePath');

    if (await targetDir.exists()) {
      final files = targetDir.listSync().whereType<File>();
      for (final file in files) {
        await file.delete();
      }
    }
  }

  /// 刪除指定的資料夾及其所有內容
  ///
  /// [relativePath] 相對於應用目錄的資料夾路徑（例如：'userId'）
  static Future<void> deleteFolder(String relativePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${baseDir.path}/$relativePath');

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
