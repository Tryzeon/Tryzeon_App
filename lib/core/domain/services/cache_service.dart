import 'dart:io';
import 'dart:typed_data';

abstract class CacheService {
  /// 保存檔案到緩存 (圖片專用)
  Future<File> saveImage(final Uint8List bytes, final String filePath);

  /// 獲取緩存的檔案 (圖片專用)
  Future<File?> getImage(final String filePath, {final String? downloadUrl});

  /// 刪除指定的緩存檔案 (圖片專用)
  Future<void> deleteImage(final String filePath);

  /// 清空所有檔案緩存
  Future<void> clearCache();
}
