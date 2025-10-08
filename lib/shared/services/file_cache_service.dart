import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileCacheService {
  /// 保存檔案到指定的緩存路徑
  ///
  /// [sourceFile] 要保存的源文件
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 保存後的檔案
  static Future<File> saveFile(File sourceFile, String filePath) async {
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

    return savedFile;
  }

  /// 獲取指定路徑的檔案
  ///
  /// [filePath] 檔案路徑（例如：'userId/avatar.jpg'）
  ///
  /// Returns 找到的檔案，如果不存在則返回 null
  static Future<File?> getFile(String filePath) async {
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
  static Future<List<File>> getFiles({
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
  static Future<void> deleteFile(String filePath) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final file = File('${baseDir.path}/$filePath');

    if (await file.exists()) {
      await file.delete();
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
