import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像（優先從本地獲取，本地沒有才從後端拿）
  static Future<Result<File>> getAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure('請重新登入');
    }

    try {
      // 1. 檢查本地是否有緩存
      final cachedFiles = await CacheService.getImages(
        relativePath: '$userId/avatar',
      );
      if (cachedFiles.isNotEmpty) {
        return Result.success(data: cachedFiles.first);
      }

      // 2. 從 Supabase 查詢檔案名稱
      final files = await _supabase.storage
          .from(_bucket)
          .list(path: '$userId/avatar');
      if (files.isEmpty) {
        return Result.success();
      }

      final fileName = '$userId/avatar/${files.first.name}';

      // 3. 下載並保存到本地緩存
      final bytes = await _supabase.storage.from(_bucket).download(fileName);
      final savedFile = await CacheService.saveImage(bytes, fileName);

      return Result.success(data: savedFile);
    } catch (e) {
      return Result.failure('獲取頭像失敗', error: e);
    }
  }

  /// 上傳頭像（先上傳到後端，成功後才保存到本地）
  static Future<Result<File>> uploadAvatar(final File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Result.failure('請重新登入');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId/avatar/$timestamp.jpg';

    try {
      // 1. 先刪除舊頭像（本地和 Supabase）
      await _deleteOldAvatars(userId);

      // 2. 上傳到 Supabase
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      // 3. 保存新的頭像到本地
      final savedFile = await CacheService.saveImage(bytes, fileName);
      return Result.success(data: savedFile);
    } catch (e) {
      return Result.failure('上傳頭像失敗', error: e);
    }
  }

  /// 刪除舊頭像（Supabase 和本地）
  static Future<void> _deleteOldAvatars(final String userId) async {
    // 刪除 Supabase 中的舊頭像
    final files = await _supabase.storage
        .from(_bucket)
        .list(path: '$userId/avatar');
    if (files.isNotEmpty) {
      await _supabase.storage.from(_bucket).remove([
        '$userId/avatar/${files.first.name}',
      ]);
    }

    // 刪除本地舊頭像
    await CacheService.deleteImages(relativePath: '$userId/avatar');
  }
}
