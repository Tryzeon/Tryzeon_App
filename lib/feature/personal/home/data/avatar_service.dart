import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像
  static Future<Result<({String avatarPath, File avatarFile})?, String>> getAvatar({
    final bool forceRefresh = false,
  }) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      if (forceRefresh) {
        final response = await _supabase.auth.refreshSession();
        user = response.session?.user ?? user;
      }

      final avatarPath = user.userMetadata?['avatar_path'] as String?;
      if (avatarPath == null || avatarPath.isEmpty) {
        return const Ok(null);
      }

      final cachedAvatar = await CacheService.getImage(avatarPath);
      if (cachedAvatar != null) {
        return Ok((avatarPath: avatarPath, avatarFile: cachedAvatar));
      }

      final url = await _supabase.storage.from(_bucket).createSignedUrl(avatarPath, 3600);
      final avatar = await CacheService.getImage(avatarPath, downloadUrl: url);

      if (avatar == null) {
        return const Err('無法獲取頭像檔案，請稍後再試');
      }

      return Ok((avatarPath: avatarPath, avatarFile: avatar));
    } catch (e) {
      AppLogger.error('頭像獲取失敗', e);
      return const Err('無法取得頭像，請稍後再試');
    }
  }

  /// 上傳頭像
  static Future<Result<({String avatarPath, File avatarFile})?, String>> uploadAvatar(
    final File image,
  ) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      final response = await _supabase.auth.refreshSession();
      user = response.session?.user ?? user;

      final oldAvatarPath = user.userMetadata?['avatar_path'] as String?;

      // 1. 準備新檔案路徑
      final imageName = p.basename(image.path);
      final avatarPath = '${user.id}/avatar/$imageName';

      final mimeType = lookupMimeType(image.path);

      // 2. 上傳到 Storage (先上傳，確保成功)
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            avatarPath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      // 3. 更新 Metadata
      await _supabase.auth.updateUser(UserAttributes(data: {'avatar_path': avatarPath}));

      // 4. 保存圖片到本地緩存
      final avatar = await CacheService.saveImage(bytes, avatarPath);

      // 5. 非同步刪除舊頭像 (清理操作，不阻塞主流程)
      if (oldAvatarPath != null && oldAvatarPath.isNotEmpty) {
        _deleteOldAvatar(oldAvatarPath).ignore();
      }

      return Ok((avatarPath: avatarPath, avatarFile: avatar));
    } catch (e) {
      AppLogger.error('頭像上傳失敗', e);
      return const Err('頭像上傳失敗，請稍後再試');
    }
  }

  /// 內部方法：刪除舊頭像
  static Future<void> _deleteOldAvatar(final String oldAvatarPath) async {
    try {
      await _supabase.storage.from(_bucket).remove([oldAvatarPath]);
      await CacheService.deleteImage(oldAvatarPath);
    } catch (e) {
      AppLogger.error('舊頭像清理失敗: $oldAvatarPath', e);
    }
  }
}
