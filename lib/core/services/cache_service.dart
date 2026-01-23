import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;
import 'package:tryzeon/core/utils/app_logger.dart';

class CacheService {
  /// 保存檔案到緩存 (圖片專用)
  static Future<File> saveImage(final Uint8List bytes, final String filePath) async {
    try {
      return await fcm.DefaultCacheManager().putFile(filePath, bytes, key: filePath);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save image to $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// 獲取緩存的檔案 (圖片專用)
  static Future<File?> getImage(
    final String filePath, {
    final String? downloadUrl,
  }) async {
    try {
      if (downloadUrl != null && downloadUrl.isNotEmpty) {
        return await fcm.DefaultCacheManager().getSingleFile(downloadUrl, key: filePath);
      }

      final fileInfo = await fcm.DefaultCacheManager().getFileFromCache(filePath);
      return fileInfo?.file;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get image from $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// 刪除指定的緩存檔案 (圖片專用)
  static Future<void> deleteImage(final String filePath) async {
    try {
      await fcm.DefaultCacheManager().removeFile(filePath);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete image at $filePath', e, stackTrace);
      rethrow;
    }
  }

  /// 清空所有檔案緩存
  static Future<void> clearCache() async {
    try {
      await fcm.DefaultCacheManager().emptyCache();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to empty cache', e, stackTrace);
    }
  }
}
