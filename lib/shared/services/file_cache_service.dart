import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 通用的檔案緩存服務
/// 提供保存、讀取、刪除檔案到本地緩存的功能
class FileCacheService {
  /// 保存檔案到指定的緩存路徑
  ///
  /// [sourceFile] 要保存的源文件
  /// [relativePath] 相對於應用文檔目錄的路徑（例如：'avatars/user123'）
  /// [fileName] 檔案名稱（例如：'avatar_123456.jpg'）
  /// [deleteOldFiles] 是否刪除目錄中的舊檔案（預設為 false）
  /// [filePattern] 當 deleteOldFiles 為 true 時，指定要刪除的檔案模式（例如：'avatar_'）
  ///
  /// Returns 保存後的檔案
  static Future<File> saveFile({
    required File sourceFile,
    required String relativePath,
    required String fileName,
    bool deleteOldFiles = false,
    String? filePattern,
  }) async {
    // 如果需要刪除舊檔案
    if (deleteOldFiles) {
      await deleteFiles(
        relativePath: relativePath,
        filePattern: filePattern,
      );
    }

    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${directory.path}/$relativePath');

    // 創建目錄（如果不存在）
    if (!targetDir.existsSync()) {
      await targetDir.create(recursive: true);
    }

    // 保存檔案
    final targetPath = '${targetDir.path}/$fileName';
    final savedFile = await sourceFile.copy(targetPath);

    return savedFile;
  }

  /// 獲取指定路徑下的檔案
  ///
  /// [relativePath] 相對於應用文檔目錄的路徑
  /// [filePattern] 要查找的檔案模式（例如：'avatar_'），如果為 null 則返回目錄中的第一個檔案
  ///
  /// Returns 找到的檔案，如果不存在則返回 null
  static Future<File?> getFile({
    required String relativePath,
    String? filePattern,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${directory.path}/$relativePath');

    if (!targetDir.existsSync()) return null;

    final files = targetDir.listSync().whereType<File>();

    if (filePattern != null) {
      final matchedFiles = files.where((f) => f.path.contains(filePattern));
      return matchedFiles.isEmpty ? null : matchedFiles.first;
    }

    return files.isEmpty ? null : files.first;
  }

  /// 獲取指定路徑下所有符合模式的檔案
  ///
  /// [relativePath] 相對於應用文檔目錄的路徑
  /// [filePattern] 要查找的檔案模式（選填）
  ///
  /// Returns 找到的檔案列表
  static Future<List<File>> getFiles({
    required String relativePath,
    String? filePattern,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${directory.path}/$relativePath');

    if (!targetDir.existsSync()) return [];

    final files = targetDir.listSync().whereType<File>();

    if (filePattern != null) {
      return files.where((f) => f.path.contains(filePattern)).toList();
    }

    return files.toList();
  }

  /// 刪除指定路徑下的檔案
  ///
  /// [relativePath] 相對於應用文檔目錄的路徑
  /// [filePattern] 要刪除的檔案模式（選填），如果為 null 則刪除目錄中的所有檔案
  static Future<void> deleteFiles({
    required String relativePath,
    String? filePattern,
  }) async {
    final files = await getFiles(
      relativePath: relativePath,
      filePattern: filePattern,
    );

    for (final file in files) {
      if (file.existsSync()) {
        await file.delete();
      }
    }
  }
}
